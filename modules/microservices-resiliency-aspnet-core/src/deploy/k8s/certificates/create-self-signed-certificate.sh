#!/bin/bash

# This certificate includes the Subject Alternate Name (SAN) that's required by Chrome.

echo
echo "host: $ESHOP_HOST (IP: $ESHOP_LBIP)"

if [ "$ESHOP_HOST" != "" ] && [ "$ESHOP_HOST" != "$ESHOP_LBIP" ]
then
  hostEntry=",DNS:$ESHOP_HOST" 
fi

if [ -f self-signed.cert.txt ]
then
    if grep -q "DNS:$ESHOP_HOST" self-signed.cert.txt 
    then
        exit 0
    fi
fi

echo
echo "Creating a development self-signed certificate"

openssl req \
-x509 \
-newkey rsa:2048 \
-sha256 \
-days 35 \
-nodes \
-keyout self-signed.key \
-out self-signed.cert.pem \
-subj '/CN=eshoplearn.development/O=eShop Learn (Development) - Self-signed' \
-extensions san \
-config <( \
  echo "[req]"; \
  echo "distinguished_name=req"; \
  echo "[san]"; \
  echo "subjectAltName=DNS:eshoplearn.local,DNS:eshoplearn.aks$hostEntry")

openssl x509 -in self-signed.cert.pem -text -noout > self-signed.cert.txt
