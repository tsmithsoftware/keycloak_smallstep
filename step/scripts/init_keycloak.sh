#! /bin/bash
# wait for certs to become available
# wait for 5 seconds to allow SSL container to do its magic - fingerprint may be old and not yet replaced
sleep 5s

# Block until the given file appears or the given timeout is reached.
# Exit status is 0 iff the file exists.
wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout
  test $wait_seconds -lt 1 && echo 'At least 1 second is required' && return 1

  until test $((wait_seconds--)) -eq 0 -o -e "$file" ; do sleep 1; done

  test $wait_seconds -ge 0 # equivalent: let ++wait_seconds
}

echo "waiting for certificates to become available..."
# Use the default timeout of 10 seconds:
wait_file keycloak_certs/keycloak.crt && {
  echo "File found."
}

wait_file aspnet_certs/aspnet_core.crt && {
  echo "File found."
}

#KC
echo "import KC cert, use pregenerated keystore"
echo "yes" | keytool -importcert -noprompt \
 -alias keycloak \
 -file /home/keycloak_certs/keycloak.crt \
 -keystore /keycloak_keystore/keystore.jks \
 -storepass password \
 -keypass password \
 -keyalg RSA

echo "import aspnet cert, use pregenerated keystore"
echo "yes" | keytool -importcert -noprompt \
 -alias keycloak \
 -file /home/aspnet_certs/aspnet_core.crt \
 -keystore /keycloak_keystore/keystore.jks \
 -storepass password \
 -keypass hello \
 -keyalg RSA

# run keycloak using certificates creating using smallstep
/opt/keycloak/bin/kc.sh start --log-level=warn --hostname-url=https://keycloak.example --https-certificate-file=/home/keycloak_certs/keycloak.crt --https-certificate-key-file=/home/keycloak_certs/keycloak.key --import-realm
