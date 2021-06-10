#!/bin/bash

echo
echo "Creating AKS with advanced networking"
echo "====================================="

if [ -f ~/clouddrive/source/create-aks-exports.txt ]
then
    eval $(cat ~/clouddrive/source/create-aks-exports.txt)
fi

if [ -z "$ESHOP_RG" ] || [ -z "$ESHOP_LOCATION" ]
then
    echo "Resource group (ESHOP_RG) and location (ESHOP_LOCATION) variables must be defined in the environment!"
    exit 1
fi

appVNet="app-vnet"
aksSubNet="aks-subnet"
appgwAksName="eshop-learn-ag-aks"

echo
echo "Creating VNET \"$appVNet\" in RG \"$ESHOP_RG\" and location \"$ESHOP_LOCATION\""
echo "-------------"

az network vnet create \
    --name $appVNet \
    --resource-group $ESHOP_RG \
    --address-prefix 10.0.0.0/8 \
    --subnet-name $aksSubNet \
    --subnet-prefix 10.241.0.0/16 \
    --query "{AddressSpace:newVNet.addressSpace,Location:newVNet.location,Name:newVNet.name}"

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo
echo "- Getting AKS subnet resourceId..."

aksSubNetResourceId=$(az network vnet subnet show \
    --name $aksSubNet \
    --vnet-name $appVNet \
    --resource-group $ESHOP_RG \
    --query id \
    --output tsv)

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo
echo "Creating AKS cluster \"$appgwAksName\" in RG \"$ESHOP_RG\" and location \"$ESHOP_LOCATION\""
echo "--------------------"

az aks create \
    --name $appgwAksName \
    --resource-group $ESHOP_RG \
    --node-count 1 \
    --vm-set-type VirtualMachineScaleSets \
    --location $ESHOP_LOCATION \
    --enable-managed-identity \
    --generate-ssh-keys \
    --network-plugin azure \
    --vnet-subnet-id $aksSubNetResourceId \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --generate-ssh-keys \
    --max-pods 110 \
    --query "{Name:name,ResourceGroup:resourceGroup,Location:location,Fqdn:fqdn,DnsPrefix:dnsPrefix,EnableRbac:enableRbac,MaxAgentPools:maxAgentPools,NodeResourceGroup:nodeResourceGroup,ProvisioningState:provisioningState}"

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo
echo "- Getting AKS principal ID..."
aksPrincipalId=$(az aks show \
    --name $appgwAksName \
    --resource-group $ESHOP_RG \
    --query identity.principalId \
    --output tsv)

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo
echo "- Getting VNET resource ID..."
appVNetResourceId=$(az network vnet show \
    --name $appVNet \
    --resource-group $ESHOP_RG \
    --query id \
    --output tsv)

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo
echo "- Asigning Network Contributor role on VNET to AKS..."
az role assignment create \
    --role "Network Contributor" \
    --assignee-object-id $aksPrincipalId \
    --scope $appVNetResourceId \
    --output none

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo
echo "Saving cluster credentials to ~/.kube/config..."
echo "--------------------------"

## Register cluster in kubeconfig
az aks get-credentials \
    --name $appgwAksName \
    --resource-group $ESHOP_RG \
    --overwrite-existing

aksNodeRg=$(az aks list --query "[?name=='$appgwAksName'&&resourceGroup=='$ESHOP_RG'].nodeResourceGroup" -otsv)

echo "export ESHOP_RG=$ESHOP_RG" > create-advanced-network-aks-exports.txt
echo "export ESHOP_LOCATION=$ESHOP_LOCATION" >> create-advanced-network-aks-exports.txt
echo "export ESHOP_APPGWAKSNAME=$appgwAksName" >> create-advanced-network-aks-exports.txt
echo "export ESHOP_APPGWAKSNODERG=$aksNodeRg" >> create-advanced-network-aks-exports.txt
echo "export ESHOP_APPVNET=$appVNet" >> create-advanced-network-aks-exports.txt
echo "export ESHOP_AKSSUBNET=$aksSubNet" >> create-advanced-network-aks-exports.txt
echo 
echo create-advanced-network-aks-exports
echo -----------------------------------
cat create-advanced-network-aks-exports.txt
echo 
echo "Run the following command to update the environment"
echo 'eval $(cat ~/clouddrive/source/create-advanced-network-aks-exports.txt)'

mv -f create-advanced-network-aks-exports.txt ~/clouddrive/source/
