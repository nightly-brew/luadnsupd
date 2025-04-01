#!/bin/sh

set -o pipefail

LUADNS_API_URL="https://api.luadns.com/v1"
PUBIP_URL="https://ipinfo.io/ip"

# Exit with an error if SIGUSR1 is received
main_process="$$"
trap "exit 1" 10

fatal() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") | $@" >&2
  kill -10 "$main_process"
}

precheck() {
  if [ -z "$LUADNS_USER" ]; then
    fatal "LUADNS_USER is not set"
  fi
  if [ -z "$LUADNS_TOKEN" ]; then
    fatal "LUADNS_TOKEN is not set"
  fi
  if [ -z "$LUADNS_ZONE_ID" ]; then
    fatal "LUADNS_ZONE_ID is not set"
  fi
  if [ -z "$LUADNS_RECORD_NAME" ]; then
    fatal "LUADNS_RECORD_NAME is not set"
  fi
}

# Example: luadnsupd_api "PUT" "/zones/12345/record/6789" "$payload"
luadns_api() {
  curl \
    -sS \
    --user    "$LUADNS_USER:$LUADNS_TOKEN" \
    --header  "Content-Type: application/json" \
    --header  "Accept: application/json" \
    --request "$1" \
    --data "$3" \
    "$LUADNS_API_URL$2" 
}

# Example: luadnsupd_get_record "ZONE_A" "URL_NAME"
luadns_get_record() {
  luadns_api "GET" "/zones/$1/records" | jq "[.[]|select(.name==\"$2\")][0]"
  
  if [ $? -ne 0 ]; then
    fatal "Could not get the requested record"
  fi
}

# Example: luadnsupd_set_record_ip "RECORD_JSON_DATA" "70.93.45.222"
luadns_set_record_ip() {
  zone_id="$(echo "$1" | jq '.zone_id')"
  record_id="$(echo "$1" | jq '.id')"

  record_name="$(echo "$1" | jq '.name')"
  record_type="$(echo "$1" | jq '.type')"
  record_ttl="$(echo "$1" | jq '.ttl')"

  payload="{\"name\":$record_name,\"type\":$record_type,\"content\":\"$2\",\"ttl\":$record_ttl}"

  luadns_api "PUT" "/zones/$zone_id/records/$record_id" "$payload"

  if [ $? -ne 0 ]; then
    fatal "Failed to update the record"
  fi
}

# Example: luadnsupd_get_record_ip "RECORD_JSON_DATA"
luadns_get_record_ip() {
  echo "$1" | jq -r '.content'
}

get_public_ip() {
  curl -sS "$PUBIP_URL"

  if [ $? -ne 0 ]; then
    fatal "Could not obtain the public ip"
  fi
}


precheck

record="$(luadns_get_record "$LUADNS_ZONE_ID" "$LUADNS_RECORD_NAME")"
record_ip="$(luadns_get_record_ip "$record")"
public_ip="$(get_public_ip)"

if [ "$record_ip" != "$public_ip" ]; then
  luadns_set_record_ip "$record" "$public_ip"
  echo "$(date "+%Y-%m-%d %H:%M:%S") | Successfully updated $LUADNS_RECORD_NAME to point $public_ip"
else
  echo "$(date "+%Y-%m-%d %H:%M:%S") | $LUADNS_RECORD_NAME points to $record_ip"
  echo "$(date "+%Y-%m-%d %H:%M:%S") | Current public ip is $public_ip"
  echo "$(date "+%Y-%m-%d %H:%M:%S") | Record is up to date"
fi