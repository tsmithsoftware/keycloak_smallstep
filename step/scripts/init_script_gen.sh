#! /bin/bash
# get the certificate fingerprint to run from a shared volume
# shared_cert_location pulled from env file

# wait for 5 seconds to allow SSL container to do its magic - fingerprint may be old and not yet replaced
sleep 5s
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

echo "finding CA fingerprint..."
CA_FINGERPRINT=$(cat $SHARED_CERT_LOCATION)
if [ -z "$CA_FINGERPRINT" ]; then
    sleep 5s #allows certificate fingerprint to be written to volume
    echo "No CA fingerprint found in shared volume! Exiting..."
    exit 1
fi
echo "CA fingerprint found."

echo "using step ca bootstrap to initialise container with new trusted cert..."
step ca bootstrap --force --ca-url https://smallstep_ca:6783 --fingerprint $CA_FINGERPRINT 2>&1 >/dev/null
if [ -e  /home/step/.step/certs/root_ca.crt ]
then
    echo "root CA initialised ok"
else
    echo "root CA not initialisaed nok"
    exit 1
fi

echo "removing previous certificates..."
rm -rf /keycloak_certs/
# get a certificate and add SSL certificates to container

echo hello > /keycloak_certs/password_file
echo hello > /keycloak_certs/provisioner_password_file

echo "obtaining a certificate from smallstep..."
step ca certificate keycloak_two /keycloak_certs/keycloak.crt /keycloak_certs/keycloak.key -ca-url=https://smallstep_ca:6783 --password-file=/keycloak_certs/password_file --provisioner-password-file=/keycloak_certs/provisioner_password_file
if [ -e /keycloak_certs/keycloak.crt ]
then
    echo "ok, crt exists"
else
    echo "nok"
    exit 1
fi
if [ -e /keycloak_certs/keycloak.key ]
then
    echo "ok, key exists"
else
    echo "nok"
    exit 1
fi
echo "done, cert and key created"

echo "running cert check..."
step certificate inspect /keycloak_certs/keycloak.crt

