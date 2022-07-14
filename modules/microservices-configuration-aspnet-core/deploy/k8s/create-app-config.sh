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

if [ -z "$ESHOP_RG" ] || [ -z "$ESHOP_LOCATION" ]
then
    echo "One or more required environment variables are missing:"
    echo "- ESHOP_RG: $ESHOP_RG"
    echo "- ESHOP_LOCATION.: $ESHOP_LOCATION"
    exit 1
fi

eshopRg=${ESHOP_RG}
eshopLocation=${ESHOP_LOCATION}
eshopIdTag=${ESHOP_IDTAG}

# App Config Creation

if [ -z "$eshopIdTag" ]
then
    dateString=$(date "+%Y%m%d%H%M%S")
    random=`head /dev/urandom | tr -dc 0-9 | head -c 3 ; echo ''`

    eshopIdTag="$dateString$random"
fi

appConfigName=eshoplearn$eshopIdTag

echo
echo "Creating App Configuration ${headingStyle}$appConfigName${defaultTextStyle} in resource group ${headingStyle}$ESHOP_RG${defaultTextStyle}"...
echo 

configCmd="az appconfig create --resource-group $ESHOP_RG --name $appConfigName --location $ESHOP_LOCATION --sku Standard --output none"
echo "${newline} > ${azCliCommandStyle}$configCmd${defaultTextStyle}${newline}"
eval $configCmd

if [ ! $? -eq 0 ]
then
    echo "${errorStyle}ERROR creating App Configuration!${defaultTextStyle}"
    exit 1
fi

echo "Done!"
echo 
echo "Retrieving App Configuration connection string..."
echo 

credCmd="az appconfig credential list  --resource-group $ESHOP_RG --name $appConfigName --query [0].connectionString --output tsv"
echo "${newline} > ${azCliCommandStyle}$credCmd${defaultTextStyle}${newline}"
connectionString=`$credCmd`
echo $connectionString
echo

echo export ESHOP_APPCONFIGNAME=$appConfigName > create-appconfig-exports.txt
echo export ESHOP_APPCONFIGCONNSTRING=$connectionString >> create-appconfig-exports.txt
echo export ESHOP_IDTAG=$eshopIdTag >> create-appconfig-exports.txt

mv -f create-appconfig-exports.txt ../..
