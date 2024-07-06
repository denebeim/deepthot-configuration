#!/bin/bash
# Exports the tls certs from k8s to a directory.

mkdir -p /media/auto/public/certs
cat <<EOF >/media/auto/public/certs/cert.pem

-----BEGIN CERTIFICATE-----
$(kubectl get secret deepthot-org-prod-tls -n traefik -o json|jq -r '.data."tls.crt"')
-----END CERTIFICATE-----
EOF

cat <<EOF >/media/auto/public/certs/key.pem

-----BEGIN CERTIFICATE-----
$(kubectl get secret deepthot-org-prod-tls -n traefik -o json|jq -r '.data."tls.key"')
-----END CERTIFICATE-----
EOF

