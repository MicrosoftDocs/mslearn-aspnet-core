#!/bin/bash

if [ -f ~/clouddrive/source/create-aks-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-aks-exports.txt)
fi

if [ -f ~/clouddrive/source/create-acr-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-acr-exports.txt)
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

# Uninstall charts to be updated
for chart in webspa webstatus webshoppingagg
do
    echo
    echo "Uninstalling chart \"$chart\"..."
    helm uninstall eshop-$chart
done

# Install reconfigured charts
for chart in webstatus webshoppingagg
do
    echo
    echo "Installing chart \"$chart\"..."
    helm install eshop-$chart --set registry=eshoplearn --set aksLB=$ESHOP_LBIP "helm-simple/$chart"
done

# Install charts for new and updated applications
for chart in coupon webspa 
do
    echo
    echo "Installing chart \"$chart\"..."
    helm install eshop-$chart --set registry=$ESHOP_REGISTRY --set aksLB=$ESHOP_LBIP "helm-simple/$chart"
done
