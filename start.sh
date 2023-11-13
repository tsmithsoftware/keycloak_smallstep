#! /bin/bash
export SHARED_CERT_LOCATION=./shared_volume/ca_fingerprint
export KC_CRT_LOCATION=./step/keycloak_certs/keycloak.crt
export KC_KEY_LOCATION=./step/keycloak_certs/keycloak.key
echo "file location: $SHARED_CERT_LOCATION"

# Block until the given file appears or the given timeout is reached.
# Exit status is 0 iff the file exists.
wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout
  test $wait_seconds -lt 1 && echo 'At least 1 second is required' && return 1

  until test $((wait_seconds--)) -eq 0 -o -e "$file" ; do sleep 1; done

  test $wait_seconds -ge 0 # equivalent: let ++wait_seconds
}

# Use the default timeout of 10 seconds:
wait_file $SHARED_CERT_LOCATION && {
  echo "File found."
}
if [ -e $SHARED_CERT_LOCATION ]
then
    echo "removing previously existing fingerprint"
    rm -f $SHARED_CERT_LOCATION
fi

echo "root ca fingerprint generated, removing previous KC certs..."
if [ -e $KC_CRT_LOCATION ]
then 
    echo "removing previously existing KC cert"
    rm -f $KC_CRT_LOCATION
fi

if [ -e $KC_KEY_LOCATION ]
then 
    echo "removing previously existing KC KEY"
    rm -f $KC_KEY_LOCATION
fi

echo "file deleted, bringing up compose..."
docker-compose up