#! /bin/bash
# this script runs on the Smallstep container to initialise the container and set up smallstep
# removing previous configuration due to inability to pass in --force params for overwriting previously generated certs and keys
# note - dns is the container name for the ca
rm -rf /home/step/
step ca init --deployment-type=standalone --name=Smallstep --dns=smallstep_ca --address=:6783 --provisioner=me@smallstep.com --password-file=/home/passwords/password_file --provisioner-password-file=/home/passwords/provisioner_password_file
# write fingerprint to shared volume for purposes of usage within docker-compose setup
# shared_cert_location pulled from env file
step certificate fingerprint /home/step/certs/root_ca.crt > $SHARED_CERT_LOCATION
# initialise step
step-ca $(step path)/config/ca.json --password-file=/home/passwords/password_file
exec "$@"