#!/usr/bin/with-contenv bash
set -euo pipefail
mkdir -p /etc/kamailio/tls

# Leggi le env scritte da 00-export-env.sh (compat v2/v3)
read_env() {
  local name="$1"
  local val=""
  if [ -f "/run/s6/container_environment/${name}" ]; then
    val="$(cat "/run/s6/container_environment/${name}")"
  elif [ -f "/var/run/s6/container_environment/${name}" ]; then
    val="$(cat "/var/run/s6/container_environment/${name}")"
  fi
  echo -n "$val"
}

export WS_PORT="$(read_env WS_PORT)"
export ADVERTISED_IP="$(read_env ADVERTISED_IP)"
export DAHUA_ADDR="$(read_env DAHUA_ADDR)"
export EXT_KAM="$(read_env EXT_KAM)"
export EXT_CARD="$(read_env EXT_CARD)"

# Render template
envsubst < /etc/kamailio/kamailio.tpl.cfg > /etc/kamailio/kamailio.cfg
envsubst < /etc/kamailio/tls/kamailio-tls.tpl.cfg > /etc/kamailio/tls/kamailio-tls.cfg
