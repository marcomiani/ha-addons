#!/usr/bin/with-contenv bash
set -euo pipefail

OPTS=/data/options.json
[ -s "$OPTS" ] || { echo "FATAL: $OPTS not found or empty" >&2; exit 1; }

WS_PORT="$(jq -r '.ws_port' "$OPTS")"
ADVERTISED_IP="$(jq -r '.advertised_ip' "$OPTS")"
DAHUA_ADDR="$(jq -r '.dahua_addr' "$OPTS")"
EXT_KAM="$(jq -r '.ext_kam' "$OPTS")"
PWD_KAM="$(jq -r '.pwd_kam' "$OPTS")"
EXT_CARD="$(jq -r '.ext_card' "$OPTS")"
PWD_CARD="$(jq -r '.pwd_card' "$OPTS")"

for v in WS_PORT ADVERTISED_IP DAHUA_ADDR EXT_KAM PWD_KAM EXT_CARD PWD_CARD; do
  val="${!v:-}"
  if [ -z "$val" ] || [ "$val" = "null" ]; then
    echo "FATAL: missing option -> $v" >&2
    exit 1
  fi
done

# Split host:port
DAHUA_HOST="${DAHUA_ADDR%:*}"
DAHUA_PORT="${DAHUA_ADDR##*:}"
# fallback se manca la porta
if [ -z "$DAHUA_PORT" ] || [ "$DAHUA_PORT" = "$DAHUA_ADDR" ]; then
  DAHUA_PORT="5060"
fi

# Esporta nel processo corrente
export WS_PORT ADVERTISED_IP DAHUA_ADDR DAHUA_HOST DAHUA_PORTEXT_KAM PWD_KAM EXT_CARD PWD_CARD

# Rendi le env disponibili ai servizi s6 (paths v2 e v3)
for dir in /run/s6/container_environment /var/run/s6/container_environment; do
  mkdir -p "$dir"
  for v in WS_PORT ADVERTISED_IP DAHUA_ADDR DAHUA_HOST DAHUA_PORT EXT_KAM PWD_KAM EXT_CARD PWD_CARD; do
    printf '%s' "${!v}" > "${dir}/${v}"
  done
done

echo "env ok: WS_PORT=$WS_PORT ADVERTISED_IP=$ADVERTISED_IP DAHUA_ADDR=$DAHUA_ADDR"
