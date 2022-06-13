#!/bin/bash

# Color theming
if [ -f ~/clouddrive/aspnet-learn/setup/theme.sh ]
then
  . <(cat ~/clouddrive/aspnet-learn/setup/theme.sh)
fi

if [ -f ~/clouddrive/aspnet-learn/create-aks-exports.txt ]
then
  eval $(cat ~/clouddrive/aspnet-learn/create-aks-exports.txt)
fi

if [ -f ~/clouddrive/aspnet-learn/create-idtag-exports.txt ]
then
  eval $(cat ~/clouddrive/aspnet-learn/create-idtag-exports.txt)
fi

eshopRg=${ESHOP_RG}
eshopLocation=${ESHOP_LOCATION}
eshopIdTag=${ESHOP_IDTAG}

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
    echo "${newline}${errorStyle}ERROR: Resource group is mandatory. Use -g to set it${defaultTextStyle}${newline}"
    exit 1
fi

rg=`az group show -g $eshopRg -o json`

if [ -z "$rg" ]
then
    if [ -z "$eshopLocation" ]
    then
        echo "${newline}${errorStyle}ERROR: If resource group has to be created, location is mandatory. Use -l to set it.${defaultTextStyle}${newline}"
        exit 1
    fi
    echo "Creating resource group \"$eshopRg\" in location \"$eshopLocation\"..."
    az group create -n $eshopRg -l $eshopLocation
    if [ ! $? -eq 0 ]
    then
        echo "${newline}${errorStyle}ERROR: Can't create resource group${defaultTextStyle}${newline}"
        exit 1
    fi

    echo "Created resource group \"$eshopRg\" in location \"$eshopLocation\"."

else
    if [ -z "$eshopLocation" ]
    then
        eshopLocation=`az group show -g $eshopRg --query "location" -otsv`
    fi
fi

# ACR Creation

eshopAcrName=${ESHOP_ACRNAME}

if [ -z "$eshopAcrName" ]
then

    if [ -z "$eshopIdTag" ]
    then
        dateString=$(date "+%Y%m%d%H%M%S")
        random=`head /dev/urandom | tr -dc 0-9 | head -c 3 ; echo ''`

        eshopIdTag="$dateString$random"
    fi

    echo
    echo "Creating Azure Container Registry \"eshoplearn$eshopIdTag\" in resource group \"$eshopRg\"..."
    acrCommand="az acr create --name eshoplearn$eshopIdTag -g $eshopRg -l $eshopLocation -o json --sku basic --admin-enabled --query \"name\" -otsv"
    echo "${newline} > ${azCliCommandStyle}$acrCommand${defaultTextStyle}${newline}"
    eshopAcrName=`$acrCommand`

    if [ ! $? -eq 0 ]
    then
        echo "${newline}${errorStyle}ERROR creating ACR!${defaultTextStyle}${newline}"
        exit 1
    fi

    echo ACR instance created!
    echo
fi

eshopRegistry=`az acr show -n $eshopAcrName --query "loginServer" -otsv`

if [ -z "$eshopRegistry" ]
then
    echo "${newline}${errorStyle}ERROR! ACR server $eshopAcrName doesn't exist!${defaultTextStyle}${newline}"
    exit 1
fi

eshopAcrCredentials=`az acr credential show -n $eshopAcrName --query "[username,passwords[0].value]" -otsv`
eshopAcrUser=`echo "$eshopAcrCredentials" | head -1`
eshopAcrPassword=`echo "$eshopAcrCredentials" | tail -1`

# Grant permisions to AKS if created
aksIdentityObjectId=$(az aks show -g $eshopRg -n $ESHOP_AKSNAME --query identityProfile.kubeletidentity.objectId -otsv)

if [ ! -z "$aksIdentityObjectId" ]
then
    acrResourceId=$(az acr show -n $eshopAcrName -g $eshopRg --query id -o tsv)

    az role assignment create \
        --role AcrPull \
        --assignee-object-id $aksIdentityObjectId \
        --scope $acrResourceId \
        --output none
fi

echo export ESHOP_RG=$eshopRg >> create-acr-exports.txt
echo export ESHOP_LOCATION=$eshopLocation >> create-acr-exports.txt
echo export ESHOP_AKSNAME=$ESHOP_AKSNAME >> create-acr-exports.txt
echo export ESHOP_LBIP=$ESHOP_LBIP >> create-acr-exports.txt
echo export ESHOP_ACRNAME=$eshopAcrName >> create-acr-exports.txt
echo export ESHOP_REGISTRY=$eshopRegistry >> create-acr-exports.txt
echo export ESHOP_ACRUSER=$eshopAcrUser >> create-acr-exports.txt
echo export ESHOP_ACRPASSWORD=$eshopAcrPassword >> create-acr-exports.txt
echo export ESHOP_IDTAG=$eshopIdTag >> create-acr-exports.txt

echo export ESHOP_IDTAG=$eshopIdTag >> create-idtag-exports.txt

echo 
echo "Created Azure Container Registry \"$eshopAcrName\" in resource group \"$eshopRg\" in location \"$eshopLocation\"." 

mv -f create-acr-exports.txt ~/clouddrive/aspnet-learn/
mv -f create-idtag-exports.txt ~/clouddrive/aspnet-learn/
