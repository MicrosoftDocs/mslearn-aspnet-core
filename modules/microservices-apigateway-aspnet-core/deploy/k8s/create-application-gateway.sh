#!/bin/bash

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

# AZ CLI check
. <(cat ../../../../infrastructure/scripts/azure-cli-check.sh)

if [ -f ../../create-aks-exports.txt ]
then
  eval $(cat ../../create-aks-exports.txt)
fi

if [ -z "$ESHOP_RG" ] || [ -z "$ESHOP_LOCATION" ]
then
    echo "Resource group (ESHOP_RG) and location (ESHOP_LOCATION) variables must be defined in the environment!"
    exit 1
fi

echo
echo ""
echo "${newline}${bold}Creating application gateway with advanced networking...${defaultTextStyle}${newline}"


appVNet="app-vnet"
appgwSubNet="appgw-subnet"

export ESHOP_APPVNET=$appVNet

echo
echo "Creating VNET \"$appVNet\" in RG \"$ESHOP_RG\" and location \"$ESHOP_LOCATION\""
echo "-------------"

az network vnet create \
    --name $appVNet \
    --resource-group $ESHOP_RG \
    --address-prefix 11.0.0.0/8 \
    --subnet-name $appgwSubNet \
    --subnet-prefix 11.1.0.0/16 \
    --query "{AddressSpace:newVNet.addressSpace,Location:newVNet.location,Name:newVNet.name}" \
    --output table

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi
appgwPublicIpName=appgw-public-ip
appgwName=appgw

echo 
echo "Creating public-ip \"$appgwPublicIpName\""
echo "------------------"

az network public-ip create \
    --resource-group $ESHOP_RG \
    --name $appgwPublicIpName \
    --allocation-method Static \
    --sku Standard \
    --query "{IPAddress:publicIp.ipAddress,Location:publicIp.location,Name:publicIp.name,ProvisioningState:publicIp.provisioningState,ResourceGroup:publicIp.resourceGroup}" \
    --output table

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
    --priority 10010 \
    --public-ip-address $appgwPublicIpName \
    --query "{ProvisioningState:applicationGateway.provisioningState,OperationalState:applicationGateway.operationalState,SKU:applicationGateway.sku}" \
    --output table

if [ ! $? -eq 0 ]; then
    echo "ERROR!"; exit 1
fi

publicIp=$(az network public-ip show -g $ESHOP_RG -n $appgwPublicIpName --query ipAddress -o tsv)

echo "export ESHOP_RG=eshop-learn-rg" > create-application-gateway-exports.txt
echo "export ESHOP_LOCATION=westus" >> create-application-gateway-exports.txt
echo "export ESHOP_APPVNET=$appVNet" >> create-application-gateway-exports.txt
echo "export ESHOP_APPGATEWAY=$appgwName" >> create-application-gateway-exports.txt
echo "export ESHOP_APPGATEWAYRG=$ESHOP_RG" >> create-application-gateway-exports.txt
echo "export ESHOP_APPGATEWAYPUBLICIP=$publicIp" >> create-application-gateway-exports.txt

mv -f create-application-gateway-exports.txt ../..

echo "${newline}${bold}Your Application Gateway public IP address is: $publicIp ${defaultTextStyle}${newline}"


