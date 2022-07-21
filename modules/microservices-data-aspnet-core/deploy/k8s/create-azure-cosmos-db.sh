#!/bin/bash

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

# AZ CLI check
. <(cat ../../../../infrastructure/scripts/azure-cli-check.sh)

if [ -f ../../create-aks-exports.txt ]
then
  eval $(cat ../../create-aks-exports.txt)
fi

if [ -f ../../create-idtag-exports.txt ]
then
  eval $(cat ../../create-idtag-exports.txt)
fi

if [ -z "$ESHOP_RG" ] || [ -z "$ESHOP_LOCATION" ]
then
    echo "One or more required environment variables are missing:"
    echo "- ESHOP_RG.......: $ESHOP_RG"
    echo "- ESHOP_LOCATION.: $ESHOP_LOCATION"
    exit 1
fi

eshopIdTag=${ESHOP_IDTAG}

# App Config Creation

if [ -z "$eshopIdTag" ]
then
    dateString=$(date "+%Y%m%d%H%M%S")
    random=`head /dev/urandom | tr -dc 0-9 | head -c 3 ; echo ''`

    eshopIdTag="$dateString$random"
fi

cosmosAccountName=eshop-learn-$eshopIdTag
cosmosDbName=CouponDb

echo
echo "Creating Azure CosmosDB account \"$cosmosAccountName\" in resource group \"$ESHOP_RG\"..."
acdbCommand="az cosmosdb create --name $cosmosAccountName --resource-group $ESHOP_RG --kind MongoDB --locations regionName=eastus --output none"
echo "${newline} > ${azCliCommandStyle}$acdbCommand${defaultTextStyle}${newline}"
eval $acdbCommand

if [ ! $? -eq 0 ]
then
    echo "${errorStyle}Error creating CosmosDB account!${plainTextStyle}"
    exit 1
fi

echo
echo "Creating MongoDB database \"$cosmosDbName\" in \"$cosmosAccountName\"..."
mdbCommand="az cosmosdb mongodb database create --account-name $cosmosAccountName --name $cosmosDbName --resource-group $ESHOP_RG --output none"
echo "${newline} > ${azCliCommandStyle}$mdbCommand${defaultTextStyle}${newline}"
eval $mdbCommand

if [ ! $? -eq 0 ]
then
    echo "${errorStyle}Error creating MongoDB database!${plainTextStyle}"
    exit 1
fi

echo
echo "Retrieving connection string..."
csCommand="az cosmosdb keys list --type connection-strings --name $cosmosAccountName --resource-group $ESHOP_RG --query connectionStrings[0].connectionString --output tsv"
echo "${newline} > ${azCliCommandStyle}$csCommand${defaultTextStyle}${newline}"
connectionString=$(eval $csCommand)

if [ ! $? -eq 0 ]
then
    echo "${errorStyle}Error retrieving connection string!${defaultTextStyle}"
    exit 1
fi

echo export ESHOP_COSMOSACCTNAME=$cosmosAccountName >> create-azure-cosmosdb-exports.txt
echo export ESHOP_COSMOSDBCONNSTRING=$connectionString >> create-azure-cosmosdb-exports.txt
echo export ESHOP_IDTAG=$eshopIdTag >> create-azure-cosmosdb-exports.txt

echo export ESHOP_IDTAG=$eshopIdTag >> create-idtag-exports.txt

echo "${newline}${headingStyle}Connection String:${defaultTextStyle}${newline}${newline}$connectionString" 
echo 

mv -f create-azure-cosmosdb-exports.txt ../../
mv -f create-idtag-exports.txt ../../
