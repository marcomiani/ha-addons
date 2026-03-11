#!/usr/bin/with-contenv bashio
set -e

# ---------------------------------------------------------------------------
# Read options from the HA add-on configuration (/data/options.json)
# ---------------------------------------------------------------------------
DAHUA_IP=$(bashio::config 'dahua_ip')
DAHUA_PORT=$(bashio::config 'dahua_port')
WSS_PORT=$(bashio::config 'wss_port')
CERTFILE="/ssl/$(bashio::config 'certfile')"
KEYFILE="/ssl/$(bashio::config 'keyfile')"

# ---------------------------------------------------------------------------
# Detect the container IP that is reachable from the Dahua device.
# With host_network:true this is the actual server IP on the LAN.
# ---------------------------------------------------------------------------
MY_IP=$(ip route get "${DAHUA_IP}" 2>/dev/null | awk 'NR==1{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')

if [ -z "${MY_IP}" ]; then
    # Fallback: first non-loopback IPv4 address
    MY_IP=$(ip -4 addr show | awk '/inet / && !/127\.0\.0\.1/{print $2}' | cut -d/ -f1 | head -1)
fi

bashio::log.info "=== Kamailio SIP Gateway ==="
bashio::log.info "  Dahua SIP server : ${DAHUA_IP}:${DAHUA_PORT} (UDP)"
bashio::log.info "  WSS listen port  : ${WSS_PORT}"
bashio::log.info "  Local IP         : ${MY_IP}"
bashio::log.info "  Certificate      : ${CERTFILE}"
bashio::log.info "  Private key      : ${KEYFILE}"

# ---------------------------------------------------------------------------
# Validate certificate files
# ---------------------------------------------------------------------------
if [ ! -f "${CERTFILE}" ]; then
    bashio::log.fatal "Certificate file not found: ${CERTFILE}"
    exit 1
fi
if [ ! -f "${KEYFILE}" ]; then
    bashio::log.fatal "Private key file not found: ${KEYFILE}"
    exit 1
fi

# ---------------------------------------------------------------------------
# Generate Kamailio configs from templates by substituting placeholders
# ---------------------------------------------------------------------------
sed \
    -e "s|%%DAHUA_IP%%|${DAHUA_IP}|g" \
    -e "s|%%DAHUA_PORT%%|${DAHUA_PORT}|g" \
    -e "s|%%WSS_PORT%%|${WSS_PORT}|g" \
    -e "s|%%MY_IP%%|${MY_IP}|g" \
    /etc/kamailio/kamailio.cfg.template > /etc/kamailio/kamailio.cfg

sed \
    -e "s|%%CERTFILE%%|${CERTFILE}|g" \
    -e "s|%%KEYFILE%%|${KEYFILE}|g" \
    /etc/kamailio/tls.cfg.template > /etc/kamailio/tls.cfg

bashio::log.info "Starting rtpengine on ${MY_IP}..."

# Start rtpengine as a background process.
# --interface  : the LAN IP for media relay (same IP Kamailio uses for SIP)
# --listen-ng  : control socket used by Kamailio's rtpengine module (NG protocol)
# --log-level  : 5 = notice (change to 7 for debug)
# --no-fallback: hard-fail if port binding fails rather than silently degrading
rtpengine \
    --interface "${MY_IP}" \
    --listen-ng "udp:127.0.0.1:2223" \
    --log-level 5 \
    --no-fallback \
    --foreground &

RTPENGINE_PID=$!
bashio::log.info "rtpengine started (PID ${RTPENGINE_PID})"

# Give rtpengine a moment to open its control socket before Kamailio starts
sleep 1

bashio::log.info "Starting Kamailio..."

# -DD = extra debug, -E = log to stderr (captured by HA supervisor)
exec kamailio -f /etc/kamailio/kamailio.cfg -DD -E
