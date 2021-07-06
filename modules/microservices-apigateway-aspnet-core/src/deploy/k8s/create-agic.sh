#!/bin/bash

echo
echo "Creating Application Gateway Ingress Controller"
echo "==============================================="

if [ -f ~/clouddrive/mslearn-aspnet-core/create-application-gateway-exports.txt ]; then
  eval $(cat ~/clouddrive/mslearn-aspnet-core/create-application-gateway-exports.txt)
fi

if [ -f ~/clouddrive/mslearn-aspnet-core/setup-pod-identity-exports.txt ]; then
  eval $(cat ~/clouddrive/mslearn-aspnet-core/setup-pod-identity-exports.txt)
fi

if [ -z "$ESHOP_PODIDENTITY_CLIENTID" ] || [ -z "$ESHOP_PODIDENTITY_RESOURCEID" ] || [ -z "$ESHOP_APPGATEWAY" ] || [ -z "$ESHOP_APPGATEWAYRG" ]
then
    echo "One or more required environment variables are missing:"
    echo "- ESHOP_PODIDENTITY_CLIENTID..: $ESHOP_PODIDENTITY_CLIENTID"
    echo "- ESHOP_PODIDENTITY_RESOURCEID: $ESHOP_PODIDENTITY_RESOURCEID"
    echo "- ESHOP_APPGATEWAY............: $ESHOP_APPGATEWAY"
    echo "- ESHOP_APPGATEWAYRG..........: $ESHOP_APPGATEWAYRG"
    exit 1
fi

subscription=$(az account show --query 'id' -o tsv)

echo
echo "Adding the AGIC helm repo"
echo "-------------------------"

helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo
echo "Installing Application Gateway Ingress Controller"
echo "-------------------------------------------------"

helm install ingress-azure application-gateway-kubernetes-ingress/ingress-azure \
    --namespace default \
    --debug \
    --set appgw.name=$ESHOP_APPGATEWAY \
    --set appgw.resourceGroup=$ESHOP_APPGATEWAYRG \
    --set appgw.subscriptionId=$subscription \
    --set appgw.usePrivateIP=false \
    --set appgw.shared=false \
    --set armAuth.type=aadPodIdentity \
    --set armAuth.identityResourceID=$ESHOP_PODIDENTITY_RESOURCEID \
    --set armAuth.identityClientID=$ESHOP_PODIDENTITY_CLIENTID \
    --set rbac.enabled=true \
    --set verbosityLevel=3 \
    --set kubernetes.watchNamespace=default \
    --version 1.2.0

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi
