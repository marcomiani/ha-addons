#!/command/with-contenv bash
set -e
mkdir -p /etc/kamailio/tls

# Rendering template -> file reali
envsubst < /etc/kamailio/kamailio.tpl.cfg > /etc/kamailio/kamailio.cfg
envsubst < /etc/kamailio/tls/kamailio-tls.tpl.cfg > /etc/kamailio/tls/kamailio-tls.cfg
