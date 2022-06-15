#!/bin/bash
eshopRegistry=eshoplearn

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
    echo "${newline}${errorStyle}ERROR: Resource group is mandatory. Use -g to set it.${defaultTextStyle}${newline}"
    exit 1
fi

export ESHOP_RG=$eshopRg
export ESHOP_LOCATION=$eshopLocation
export ESHOP_REGISTRY=$eshopRegistry


cd ~/clouddrive/aspnet-learn/src/deploy/k8s

# AKS Cluster creation

./create-aks.sh

eval $(cat ~/clouddrive/aspnet-learn/create-aks-exports.txt)

./deploy-application.sh

