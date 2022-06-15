#!/bin/bash

echo
echo "Setting up AAD Pod identity"
echo "==========================="

if [ -f ~/clouddrive/source/create-advanced-network-aks-exports.txt ]; then
  eval $(cat ~/clouddrive/source/create-advanced-network-aks-exports.txt)
fi

if [ -f ~/clouddrive/source/create-application-gateway-exports.txt ]; then
  eval $(cat ~/clouddrive/source/create-application-gateway-exports.txt)
fi

if [ -z "$ESHOP_RG" ] || [ -z "$ESHOP_APPGWAKSNAME" ] || [ -z "$ESHOP_APPGWAKSNODERG" ] || [ -z "$ESHOP_APPGATEWAY" ] || [ -z "$ESHOP_APPGATEWAYRG" ]
then
    echo "One or more required environment variables are missing:"
    echo "- ESHOP_RG............: $ESHOP_RG"
    echo "- ESHOP_APPGWAKSNAME..: $ESHOP_APPGWAKSNAME"
    echo "- ESHOP_APPGWAKSNODERG: $ESHOP_APPGWAKSNODERG"
    echo "- ESHOP_APPGATEWAY....: $ESHOP_APPGATEWAY"
    echo "- ESHOP_APPGATEWAYRG..: $ESHOP_APPGATEWAYRG"
    exit 1
fi

podIdentityType="aks" ## aks/node
aksNodeIdentityName=aks-node-identity

if [ "$podIdentityType" == "aks" ]
then
    echo
    echo "Using AKS identity"
    echo "------------------"

    podIdentityObjectId=$(az aks show -g $ESHOP_RG -n $ESHOP_APPGWAKSNAME --query identityProfile.kubeletidentity.objectId -otsv)
    podIdentityClientId=$(az aks show -g $ESHOP_RG -n $ESHOP_APPGWAKSNAME --query identityProfile.kubeletidentity.clientId -otsv)
    podIdentityResourceId=$(az aks show -g $ESHOP_RG -n $ESHOP_APPGWAKSNAME --query identityProfile.kubeletidentity.resourceId -otsv)

    echo "Pod identity type \"$podIdentityType\" ($podIdentityObjectId)"
else

    echo
    echo "Creating identity in node RG: \"$aksNodeIdentityName\""
    echo "----------------------------"

    az identity create \
        -g $ESHOP_APPGWAKSNODERG \
        -n $aksNodeIdentityName

    if [ ! $? -eq 0 ]; then
        echo "ERROR!"; exit 1
    fi

    podIdentityObjectId=$(az identity show -g $ESHOP_APPGWAKSNODERG -n $aksNodeIdentityName --query 'principalId' -o tsv)
    podIdentityClientId=$(az identity show -g $ESHOP_APPGWAKSNODERG -n $aksNodeIdentityName --query 'clientId' -o tsv)
    podIdentityResourceId=$(az identity show -g $ESHOP_APPGWAKSNODERG -n $aksNodeIdentityName --query 'id' -o tsv)

        echo "Pod identity type \"$podIdentityType\" ($podIdentityObjectId)"
fi

aksNodeRgResourceId=$(az group show -g $ESHOP_APPGWAKSNODERG --query id -otsv)
appGwResourceId=$(az network application-gateway show -g $ESHOP_APPGATEWAYRG -n $ESHOP_APPGATEWAY --query id -otsv)
appGwRgResourceId=$(az group show -g $ESHOP_APPGATEWAYRG --query id -otsv)

echo
echo "- Assigning \"Managed Identity Operator\" role on node RG to Pod Identity..."

az role assignment create \
    --role "Managed Identity Operator" \
    --assignee-object-id $podIdentityObjectId \
    --scope $aksNodeRgResourceId \
    --output none

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo "- Assigning \"Virtual Machine Contributor\" role on node RG to Pod Identity..."

az role assignment create \
    --role "Virtual Machine Contributor" \
    --assignee-object-id $podIdentityObjectId \
    --scope $aksNodeRgResourceId \
    --output none

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo "- Assigning \"Contributor\" role on Application Gateway to Pod Identity..."

az role assignment create \
    --role Contributor \
    --assignee-object-id $podIdentityObjectId \
    --scope $appGwResourceId \
    --output none

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo "- Assigning \"Reader\" role on Application Gateway RG to Pod Identity..."

az role assignment create \
    --role Reader \
    --assignee-object-id $podIdentityObjectId \
    --scope $appGwRgResourceId \
    --output none

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo
echo "Installing AAD Pod Identity into cluster"
echo "----------------------------------------"

kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/v1.5.5/deploy/infra/deployment-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/mic-exception.yaml

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo "export ESHOP_PODIDENTITY_TYPE=$podIdentityType" > setup-pod-identity-exports.txt
echo "export ESHOP_PODIDENTITY_OBJECTID=$podIdentityObjectId" >> setup-pod-identity-exports.txt
echo "export ESHOP_PODIDENTITY_CLIENTID=$podIdentityClientId" >> setup-pod-identity-exports.txt
echo "export ESHOP_PODIDENTITY_RESOURCEID=$podIdentityResourceId" >> setup-pod-identity-exports.txt

echo
echo setup-pod-identity-exports
echo --------------------------
cat setup-pod-identity-exports.txt

mv -f setup-pod-identity-exports.txt ~/clouddrive/source/

echo 
echo "Run the following command to update the environment"
echo 'eval $(cat ~/clouddrive/source/setup-pod-identity-exports.txt)'
