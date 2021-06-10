#!/bin/bash
eshopRegistry=eshopdev

while [ "$1" != "" ]; do
    case $1 in
        -g | --resource-group)          shift
                                        eshopRg=$1
                                        ;;
        -l | --location)                shift
                                        eshopLocation=$1
                                        ;;
             * )                        echo "Invalid param: $1"
                                        exit 1
    esac
    shift
done

if [ -z "$eshopRg" ]
then
    echo "ERROR: RG is mandatory. Use -g to set it"
    exit 1
fi

export ESHOP_RG=$eshopRg
export ESHOP_LOCATION=$eshopLocation
export ESHOP_REGISTRY=$eshopRegistry

# AKS Cluster creation

./create-aks.sh

eval $(cat ~/clouddrive/source/create-aks-exports.txt)

./deploy-application.sh
