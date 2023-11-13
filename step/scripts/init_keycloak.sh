#! /bin/bash
# run keycloak using certificates creating using smallstep
/opt/keycloak/bin/kc.sh start --log-level=warn --hostname-url=https://keycloak.example --https-certificate-file=/home/keycloak_certs/keycloak.crt --https-certificate-key-file=/home/keycloak_certs/keycloak.key
