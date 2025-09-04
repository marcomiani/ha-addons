#!/usr/bin/with-contenv bash
set -e

WS_PORT=$(bashio::config 'ws_port')
ADVERTISED_IP=$(bashio::config 'advertised_ip')
DAHUA_ADDR=$(bashio::config 'dahua_addr')
EXT_KAM=$(bashio::config 'ext_kam')
PWD_KAM=$(bashio::config 'pwd_kam')
EXT_CARD=$(bashio::config 'ext_card')
PWD_CARD=$(bashio::config 'pwd_card')

for v in WS_PORT ADVERTISED_IP DAHUA_ADDR EXT_KAM PWD_KAM EXT_CARD PWD_CARD; do
  eval "val=\${$v}"
  if [ -z "$val" ]; then
    echo "FATAL: missing option -> $v" >&2
    exit 1
  fi
done

export WS_PORT ADVERTISED_IP DAHUA_ADDR EXT_KAM PWD_KAM EXT_CARD PWD_CARD
echo "env ok: WS_PORT=$WS_PORT ADVERTISED_IP=$ADVERTISED_IP DAHUA_ADDR=$DAHUA_ADDR"
