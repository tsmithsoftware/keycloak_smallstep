FROM registry.access.redhat.com/ubi9 AS ubi-micro-build
#COPY mycertificate.crt /etc/pki/ca-trust/source/anchors/mycertificate.crt
#COPY openssl.cnf /etc/pki/ca-trust/source/anchors/mycertificate.crt

FROM quay.io/keycloak/keycloak
COPY --from=ubi-micro-build /etc/pki /etc/pki