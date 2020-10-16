#!/bin/bash

echo
echo "Creating App Configuration service instance"
echo "==========================================="

if [ -f ~/clouddrive/source/create-aks-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-aks-exports.txt)
fi

if [ -f ~/clouddrive/source/create-acr-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-acr-exports.txt)
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
echo "Creating App Configuration $appConfigName in RG $ESHOP_RG"
echo "--------------------------"

az appconfig create \
    --resource-group $ESHOP_RG \
    --name $appConfigName \
    --location $ESHOP_LOCATION \
    --sku Standard \
    --query "{ProvissioningState:provissioningState,Location:location,Name:name}"

if [ ! $? -eq 0 ]
then
    echo "ERROR creating App Configuration!"
    exit 1
fi

echo
echo "Retrieving App Config connection string"
echo "---------------------------------------"
connectionString=`az appconfig credential list \
    --resource-group $ESHOP_RG \
    --name $appConfigName \
    --query [0].connectionString \
    --output tsv`

echo export ESHOP_APPCONFIGNAME=$appConfigName > create-appconfig-exports.txt
echo export ESHOP_APPCONFIGCONNSTRING=$connectionString >> create-appconfig-exports.txt
echo export ESHOP_IDTAG=$eshopIdTag >> create-appconfig-exports.txt

echo 
echo "Created Azure App Configuration $appConfigName in RG $eshopRg at location $eshopLocation." 
echo 
echo "ConnectionString: $connectionString" 
echo 
echo "Environment variables" 
echo "---------------------" 
cat create-appconfig-exports.txt
echo 
echo "Run the following command to update the environment"
echo 'eval $(cat ~/clouddrive/source/create-appconfig-exports.txt)'
echo

mv -f create-appconfig-exports.txt ~/clouddrive/source/
