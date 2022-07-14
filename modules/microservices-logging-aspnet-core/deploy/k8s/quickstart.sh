#!/bin/bash
defaultLocation="centralus"
defaultRg="eshop-learn-rg"

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

# AZ CLI check
. <(cat ../../../../infrastructure/scripts/azure-cli-check.sh)

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

if [ -z "$eshopLocation" ]
then
    echo "Using the default location: $defaultLocation"
    eshopLocation=$defaultLocation
fi

if [ -z "$eshopRg" ]
then
    echo "Using the default resource group: $defaultRg"
    eshopRg=$defaultRg
fi
echo "${bold}Note: You can change the default location and resource group by modifying the variables at the top of quickstart.sh.${defaultTextStyle}"

if [ ! -z "$eshopSubs" ]
then
    echo "Switching to subscription $eshopSubs..."
    az account set -s $eshopSubs
fi

if [ ! $? -eq 0 ]
then
    echo "${newline}${errorStyle}ERROR: Can't switch to subscription $eshopSubs.${defaultTextStyle}${newline}"
    exit 1
fi

export ESHOP_SUBS=$eshopSubs
export ESHOP_RG=$eshopRg
export ESHOP_LOCATION=$eshopLocation
export ESHOP_REGISTRY=$eshopRegistry
export ESHOP_QUICKSTART=true

# AKS Cluster creation
. <(cat ./create-aks.sh)

eval $(cat ../../create-aks-exports.txt)

. <(cat ./deploy-application.sh)

. <(cat ./create-acr.sh)

cat ../../deployment-urls.txt
