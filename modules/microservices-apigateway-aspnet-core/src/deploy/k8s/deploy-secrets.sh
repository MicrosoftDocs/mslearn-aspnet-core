kubectl delete secrets --field-selector metadata.name=tls-secret

kubectl create secret tls tls-secret --cert ./certificates/self-signed.cert.pem --key ./certificates/self-signed.key
