#!/bin/bash

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

# AZ CLI check
. <(cat ../../../../infrastructure/scripts/azure-cli-check.sh)

if [ -f ../../create-aks-exports.txt ]; then  
  eval $(cat ../../create-aks-exports.txt)
fi

if [ -f ../../create-application-gateway-exports.txt ]; then
  eval $(cat ../../create-application-gateway-exports.txt)
fi

if [ -z "$ESHOP_RG" ]  || [ -z "$ESHOP_AKSNAME" ] || [ -z "$ESHOP_APPGATEWAY" ] || [ -z "$ESHOP_APPGATEWAYRG" ] || [ -z "$ESHOP_APPVNET" ]
then
    echo "One or more required environment variables are missing:"
    echo "- ESHOP_RG..: $ESHOP_RG"
    echo "- ESHOP_AKSNAME: $ESHOP_AKSNAME"
    echo "- ESHOP_APPGATEWAY............: $ESHOP_APPGATEWAY"
    echo "- ESHOP_APPGATEWAYRG..........: $ESHOP_APPGATEWAYRG"
    echo "- ESHOP_APPVNET..........: $ESHOP_APPVNET"
    exit 1
fi

echo "${newline}${bold}Enabling the AGIC add-on...${defaultTextStyle}${newline}"

appgwId=$(az network application-gateway show -n $ESHOP_APPGATEWAY -g $ESHOP_RG -o tsv --query "id") 
az aks enable-addons -n $ESHOP_AKSNAME -g $ESHOP_RG -a ingress-appgw --appgw-id $appgwId

echo
echo "Peer the AKS and APP Gateway virtual networks together"
echo "============================"

nodeResourceGroup=$(az aks show -n $ESHOP_AKSNAME -g $ESHOP_RG -o tsv --query "nodeResourceGroup")
aksVnetName=$(az network vnet list -g $nodeResourceGroup -o tsv --query "[0].name")

aksVnetId=$(az network vnet show -n $aksVnetName -g $nodeResourceGroup -o tsv --query "id")
az network vnet peering create -n AppGWtoAKSVnetPeering -g $ESHOP_RG --vnet-name $ESHOP_APPVNET --remote-vnet $aksVnetId --allow-vnet-access

appGWVnetId=$(az network vnet show -n $ESHOP_APPVNET -g $ESHOP_RG -o tsv --query "id")
az network vnet peering create -n AKStoAppGWVnetPeering -g $nodeResourceGroup --vnet-name $aksVnetName --remote-vnet $appGWVnetId --allow-vnet-access

echo "${newline}${bold}AGIC has been enabled in your cluster!${defaultTextStyle}${newline}"
