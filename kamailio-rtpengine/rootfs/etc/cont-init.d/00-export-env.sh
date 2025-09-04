#!/usr/bin/with-contenv bash
set -euo pipefail

OPTS=/data/options.json
if [ ! -s "$OPTS" ]; then
  echo "FATAL: $OPTS not found or empty" >&2
  exit 1
fi

# Read options using jq (no bashio)
WS_PORT="$(jq -r '.ws_port' "$OPTS")"
ADVERTISED_IP="$(jq -r '.advertised_ip' "$OPTS")"
DAHUA_ADDR="$(jq -r '.dahua_addr' "$OPTS")"
EXT_KAM="$(jq -r '.ext_kam' "$OPTS")"
PWD_KAM="$(jq -r '.pwd_kam' "$OPTS")"
EXT_CARD="$(jq -r '.ext_card' "$OPTS")"
PWD_CARD="$(jq -r '.pwd_card' "$OPTS")"

# Validate
for v in WS_PORT ADVERTISED_IP DAHUA_ADDR EXT_KAM PWD_KAM EXT_CARD PWD_CARD; do
  val="${!v:-}"
  if [ -z "$val" ] || [ "$val" = "null" ]; then
    echo "FATAL: missing option -> $v" >&2
    exit 1
  fi
done

export WS_PORT ADVERTISED_IP DAHUA_ADDR EXT_KAM PWD_KAM EXT_CARD PWD_CARD
echo "env ok: WS_PORT=$WS_PORT ADVERTISED_IP=$ADVERTISED_IP DAHUA_ADDR=$DAHUA_ADDR"


export WS_PORT ADVERTISED_IP DAHUA_ADDR EXT_KAM PWD_KAM EXT_CARD PWD_CARD
echo "env ok: WS_PORT=$WS_PORT ADVERTISED_IP=$ADVERTISED_IP DAHUA_ADDR=$DAHUA_ADDR"
