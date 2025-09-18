#!/usr/bin/with-contenv bashio
set -euo pipefail

# debug: verifica binari, esce con messaggio chiaro
command -v jq >/dev/null || { bashio::log.error echo "jq non installato"; exit 1; }
command -v mosquitto_pub >/dev/null || { bashio::log.error "mosquitto_pub non installato"; exit 1; }


URL="$(bashio::config 'url')"
POLL="$(bashio::config 'poll_interval')"
DISC="$(bashio::config 'discovery_prefix')"
BASE="$(bashio::config 'base_topic')"
DEV_NAME="$(bashio::config 'device_name')"
UNIQ="$(bashio::config 'unique_prefix')"

# MQTT: usa service discovery se presente, altrimenti i parametri dell'addon
if bashio::services.available "mqtt"; then
  MQTT_HOST="$(bashio::services mqtt 'host')"
  MQTT_PORT="$(bashio::services mqtt 'port')"
  MQTT_USER="$(bashio::services mqtt 'username')"
  MQTT_PASS="$(bashio::services mqtt 'password')"
else
  MQTT_HOST="$(bashio::config 'mqtt.host')"
  MQTT_PORT="$(bashio::config 'mqtt.port')"
  MQTT_USER="$(bashio::config 'mqtt.username')"
  MQTT_PASS="$(bashio::config 'mqtt.password')"
fi

STATE_T="$BASE/state"
AVAIL_T="$BASE/availability"
DEV_JSON=$(jq -nc --arg id "${UNIQ}_inverter" --arg name "$DEV_NAME" \
  '{identifiers:[$id], name:$name, manufacturer:"ABB/Power-One"}')

pub_cfg() {
  local id="$1" name="$2" key="$3" unit="$4" dclass="$5"
  local cfg
  cfg=$(jq -nc --arg name "$name" --arg uid "$id" --arg st "$STATE_T" \
      --arg av "$AVAIL_T" --arg unit "$unit" --arg dc "$dclass" \
      --arg dev "$DEV_JSON" --arg tmpl "{{ value_json.$key }}" \
      '{
        name:$name, unique_id:$uid, state_topic:$st,
        value_template:$tmpl, unit_of_measurement:$unit,
        device_class:$dc, state_class:"measurement",
        availability_topic:$av, device: ($dev|fromjson)
      }')
  mosquitto_pub -r -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
    -t "$DISC/sensor/$id/config" -m "$cfg"
}

pub_cfg_attrs() {
  # Sensore principale: stato = G1P, attributi = PMAXOTD/PMAXOTDTIME/awdate
  local id="${UNIQ}_power" name="FV Produzione Potenza"
  local cfg
  cfg=$(jq -nc --arg name "$name" --arg uid "$id" --arg st "$STATE_T" \
      --arg av "$AVAIL_T" --arg dev "$DEV_JSON" \
      '{
        name:$name, unique_id:$uid, state_topic:$st,
        value_template:"{{ value_json.G1P }}",
        unit_of_measurement:"W", device_class:"power",
        state_class:"measurement", availability_topic:$av,
        json_attributes_topic:$st,
        json_attributes_template:"{{ {\"max_power_otd\": value_json.PMAXOTD, \"max_power_otd_time\": value_json.PMAXOTDTIME, \"awake_hour\": value_json.awdate} | tojson }}",
        device: ($dev|fromjson)
      }')
  mosquitto_pub -r -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
    -t "$DISC/sensor/$id/config" -m "$cfg"
}

bashio::log.info "Publishing MQTT discovery..."
pub_cfg_attrs
pub_cfg "${UNIQ}_g1v" "FV Tensione Grid" "G1V" "V" "voltage"
pub_cfg "${UNIQ}_g1a" "FV Corrente Grid" "G1A" "A" "current"
pub_cfg "${UNIQ}_i1v" "FV Array 1 Tensione" "I1V" "V" "voltage"
pub_cfg "${UNIQ}_i1a" "FV Array 1 Corrente" "I1A" "A" "current"
pub_cfg "${UNIQ}_i1p" "FV Array 1 Potenza" "I1P" "W" "power"
pub_cfg "${UNIQ}_i2v" "FV Array 2 Tensione" "I2V" "V" "voltage"
pub_cfg "${UNIQ}_i2a" "FV Array 2 Corrente" "I2A" "A" "current"
pub_cfg "${UNIQ}_i2p" "FV Array 2 Potenza" "I2P" "W" "power"

mosquitto_pub -r -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
  -t "$AVAIL_T" -m "online"

bashio::log.info "Starting polling loop (every ${POLL}s) from ${URL}"
while true; do
  if json=$(curl -fsS "$URL"); then
    mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
      -t "$STATE_T" -m "$json"
  else
    bashio::log.warning "Fetch failed; marking offline"
    mosquitto_pub -r -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
      -t "$AVAIL_T" -m "offline"
    sleep "$POLL"
    mosquitto_pub -r -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
      -t "$AVAIL_T" -m "online"
  fi
  sleep "$POLL"
done
