# Keycloak_Compose

This prject is a sample project using Step-CA to initialise and install SSL certificates on containers running Keycloak and an ASP.NET Core 6 web application, to use Keycloak as access manager to the web application.

The process is as follows:

* The Smallstep CA container is booted. An initialisation script is included, which creates a root certificate.
* The root certificate is used by the Step-CLI container (certificate_generator) to generate SSL certificates for the Keycloak instance. This is because the KC image is secure (locaked down), which means we are unable to install the Step CLI client on the container to bootstrap the certificates. The generated certificates are made available to the KC container for use, which is configured through the command line: 

`
/opt/keycloak/bin/kc.sh start --log-level=warn --hostname-url=https://keycloak.example --https-certificate-file=/home/keycloak_certs/keycloak.crt --https-certificate-key-file=/home/keycloak_certs/keycloak.key --import-realm
`

-> does the KC container need to have the certificates added to the trust store? I don't think so - I think passing the certs to the command should do the necessary, otherwise what's the point of the parameters?

 The root certificate is also used by the webapp container to bootstrap itself to the Step CA and obtain a leaf certificate. This certificate is converted into .pkcs format and moved into a location on the container. The webapp expects the certificates to be at this (hardcoded) location and loads them accordingly.