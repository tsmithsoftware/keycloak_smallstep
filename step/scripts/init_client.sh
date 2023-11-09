#! /bin/bash
# get the certificate fingerprint to run from a shared volume
# shared_cert_location pulled from env file
CA_FINGERPRINT=$(cat $SHARED_CERT_LOCATION)
if [ -z "CA_FINGERPRINT" ]; then
    echo "No CA fingerprint found in shared volume! Exiting..."
    exit 1
fi)
# use step ca bootstrap to initialise container with new trusted cert
step ca bootstrap --ca-url https://smallstep_ca:6783 --fingerprint $CA_FINGERPRINT
exec "$@"