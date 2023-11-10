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
if [ -z "CA_FINGERPRINT" ]; then
    sleep 5s #allows certificate fingerprint to be written to volume
    echo "No CA fingerprint found in shared volume! Exiting..."
    exit 1
fi
echo "CA fingerprint found."

echo "Adding step-cli tool..."
apk add step-cli
echo "step-cli added."

echo "using step ca bootstrap to initialise container with new trusted cert..."
step ca bootstrap --ca-url https://smallstep_ca:6783 --fingerprint $CA_FINGERPRINT 2>&1 >/dev/null
if [ -e /root/.step/certs/root_ca.crt ]
then
    echo "ok"
else
    echo "nok"
    exit 1
fi

echo "creating certificate directory"
mkdir /certs
cd /certs

# generate password files (to be improved)
echo hello > prov-pass
echo hello > password

# get a certificate and add SSL certificates to container
echo "obtaining a certificate from smallstep..."
step ca certificate aspnet_core aspnet_core.crt aspnet_core.key -ca-url=https://smallstep_ca:6783 --password-file=./password --provisioner-password-file=./prov-pass
if [ -e ./aspnet_core.crt ]
then
    echo "ok, crt exists"
else
    echo "nok"
    exit 1
fi
if [ -e ./aspnet_core.key ]
then
    echo "ok, key exists"
else
    echo "nok"
    exit 1
fi
 # https://stackoverflow.com/questions/49153782/install-certificate-in-dotnet-core-docker-container
 # copy cert into /usr/local/share/ca-certificates/your_ca.crt
echo "done, cert and key created"

echo "running cert check..."
step certificate inspect aspnet_core.crt

echo "convert into pkx"
openssl pkcs12 -export -out aspnet_core.pfx -inkey ./aspnet_core.key -in ./aspnet_core.crt -passin pass:hello -passout pass:hello

echo "show file list"
ls

echo "move into locations"

mv aspnet_core.pfx /certs/aspnet_core.pfx
# run app
cd /app

echo "Running app..."
dotnet KeycloakAuth.dll
exec "$@"