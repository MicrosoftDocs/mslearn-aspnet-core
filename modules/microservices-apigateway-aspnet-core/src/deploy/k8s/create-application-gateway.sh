#!/bin/bash

echo
echo "Creating Application Gateway"
echo "============================"

if [ -f ~/clouddrive/source/create-advanced-network-aks-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-advanced-network-aks-exports.txt)
fi

if [ -z "$ESHOP_RG" ] || [ -z "$ESHOP_LOCATION" ] || [ -z "$ESHOP_APPVNET" ]
then
    echo "Resource group (ESHOP_RG), location (ESHOP_LOCATION), and VNET (ESHOP_APPVNET) variables must be defined in the environment!"
    exit 1
fi

appgwSubNet=appgw-subnet
appgwPublicIpName=appgw-public-ip
appgwName=appgw

echo
echo "Creating subnet \"$appgwSubNet\""
echo "---------------"

az network vnet subnet create \
    --name $appgwSubNet \
    --resource-group $ESHOP_RG \
    --vnet-name $ESHOP_APPVNET \
    --address-prefix 10.242.0.0/16 \
    --query "{AddressPrefix:addressPrefix,Name:name,ProvisioningState:provisioningState,ResourceGroup:resourceGroup}"

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo 
echo "Creating public-ip \"$appgwPublicIpName\""
echo "------------------"

az network public-ip create \
    --resource-group $ESHOP_RG \
    --name $appgwPublicIpName \
    --allocation-method Static \
    --sku Standard \
    --query "{IPAddress:publicIp.ipAddress,Location:publicIp.location,Name:publicIp.name,ProvisioningState:publicIp.provisioningState,ResourceGroup:publicIp.resourceGroup}"

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

echo 
echo "Creating application-gateway \"$appgwName\""
echo "----------------------------"

az network application-gateway create \
    --name $appgwName \
    --location $ESHOP_LOCATION \
    --resource-group $ESHOP_RG \
    --vnet-name $ESHOP_APPVNET \
    --subnet $appgwSubNet \
    --capacity 1 \
    --sku WAF_v2 \
    --http-settings-cookie-based-affinity Disabled \
    --frontend-port 80 \
    --http-settings-port 80 \
    --http-settings-protocol Http \
    --public-ip-address $appgwPublicIpName \
    --query "{ProvisioningState:applicationGateway.provisioningState,OperationalState:applicationGateway.operationalState,SKU:applicationGateway.sku}"

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

publicIp=$(az network public-ip show -g $ESHOP_RG -n $appgwPublicIpName --query ipAddress -o tsv)

echo "export ESHOP_APPGATEWAY=$appgwName" > create-application-gateway-exports.txt
echo "export ESHOP_APPGATEWAYRG=$ESHOP_RG" >> create-application-gateway-exports.txt
echo "export ESHOP_APPGATEWAYPUBLICIP=$publicIp" >> create-application-gateway-exports.txt
echo 
echo create-application-gateway-exports
echo ----------------------------------
cat create-application-gateway-exports.txt
echo 
echo "Run the following command to update the environment"
echo 'eval $(cat ~/clouddrive/source/create-application-gateway-exports.txt)'

mv -f create-application-gateway-exports.txt ~/clouddrive/source/
