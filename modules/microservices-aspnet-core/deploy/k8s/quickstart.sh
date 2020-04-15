#!/bin/bash
eshopSubs=${ESHOP_SUBS}
eshopRg=${ESHOP_RG}
eshopLocation=${ESHOP_LOCATION}
eshopRegistry=eshoplearn

while [ "$1" != "" ]; do
    case $1 in
        -s | --subscription)            shift
                                        eshopSubs=$1
                                        ;;
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

if [ ! -z "$eshopSubs" ]
then
    echo "Switching to subs $eshopSubs..."
    az account set -s $eshopSubs
fi

if [ ! $? -eq 0 ]
then
    echo "ERROR: Can't switch to subscription $eshopSubs"
    exit 1
fi

export ESHOP_SUBS=$eshopSubs
export ESHOP_RG=$eshopRg
export ESHOP_LOCATION=$eshopLocation
export ESHOP_REGISTRY=$eshopRegistry
export ESHOP_QUICKSTART=true

cd ~/clouddrive/source/eShop-Learn/deploy/k8s

# AKS Cluster creation

./create-aks.sh

eval $(cat ~/clouddrive/source/create-aks-exports.txt)

./deploy-aks.sh
