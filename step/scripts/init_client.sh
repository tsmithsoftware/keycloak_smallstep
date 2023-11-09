#! /bin/bash
# get the certificate fingerprint to run from a shared volume
# shared_cert_location pulled from env file

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

CA_FINGERPRINT=$(cat $SHARED_CERT_LOCATION)
if [ -z "CA_FINGERPRINT" ]; then
    sleep 5s #allows certificate fingerprint to be written to volume
    echo "No CA fingerprint found in shared volume! Exiting..."
    exit 1
fi
apk add step-cli
# use step ca bootstrap to initialise container with new trusted cert
step ca bootstrap --ca-url https://smallstep_ca:6783 --fingerprint $CA_FINGERPRINT 2>&1 >/dev/null
exec "$@"