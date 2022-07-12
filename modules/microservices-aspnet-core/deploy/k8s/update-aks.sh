#!/bin/bash

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

# AZ CLI check
. <(cat ../../../../infrastructure/scripts/azure-cli-check.sh)

if [ -f ../../create-aks-exports.txt ]
then
  eval $(cat ../../create-aks-exports.txt)
fi

if [ -f ../../create-acr-exports.txt ]
then
  eval $(cat ../../create-acr-exports.txt)
fi

if [ -z "$ESHOP_REGISTRY" ]
then
    echo "ERROR: The ESHOP_REGISTRY environment variable is not defined."
    exit 1
fi

if [ -z "$ESHOP_LBIP" ]
then
    echo "ERROR: The ESHOP_LBIP environment variable is not defined."
    exit 1
fi

echo "Updating existing AKS deployment..."

# Uninstall charts to be updated
for chart in webspa webstatus webshoppingagg
do
    echo
    echo "Uninstalling chart \"$chart\"..."
    echo "${newline}${genericCommandStyle}helm uninstall eshop-$chart${defaultTextStyle}${newline}"
    helm uninstall eshop-$chart
done

# Install reconfigured charts from Docker Hub
for chart in webstatus webshoppingagg 
do
    echo
    echo "Installing chart \"$chart\"..."
    echo "${newline}${genericCommandStyle}helm install eshop-$chart --set registry=eshoplearn --set aksLB=$ESHOP_LBIP \"helm-simple/$chart\"${defaultTextStyle}${newline}"
    helm install eshop-$chart --set registry=eshoplearn --set aksLB=$ESHOP_LBIP "helm-simple/$chart"
done

# Install charts for new and updated applications from ACR
for chart in coupon webspa 
do
    echo
    echo "Installing chart \"$chart\"..."
    echo "${newline}${genericCommandStyle}helm install eshop-$chart --set registry=$ESHOP_REGISTRY --set aksLB=$ESHOP_LBIP \"helm-simple/$chart\"${defaultTextStyle}${newline}"
    helm install eshop-$chart --set registry=$ESHOP_REGISTRY --set aksLB=$ESHOP_LBIP "helm-simple/$chart"
done

echo "Done updating existing AKS deployment!"