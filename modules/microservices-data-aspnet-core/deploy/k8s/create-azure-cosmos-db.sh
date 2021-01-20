#!/bin/bash

echo
echo "Creating an Azure Cosmos DB instance"
echo "===================================="

if [ -f ~/clouddrive/source/create-aks-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-aks-exports.txt)
fi

if [ -f ~/clouddrive/source/create-idtag-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-idtag-exports.txt)
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

echo
echo "Creating Azure Cosmos DB account $cosmosAccountName in RG $ESHOP_RG"
echo "--------------------------------"

az cosmosdb create \
    --name $cosmosAccountName \
    --resource-group $ESHOP_RG \
    --kind MongoDB \
    --query "{DocumentEndpoint:documentEndpoint,Kind:kind,Name:name,Location:location}"

if [ ! $? -eq 0 ]
then
    echo "ERROR!"
    exit 1
fi

echo
echo "Creating MongoDB database $cosmosDbName in RG $ESHOP_RG"
echo "-------------------------"

az cosmosdb mongodb database create \
    --account-name $cosmosAccountName \
    --name CouponDb \
    --resource-group $ESHOP_RG \
    --query "{Name:name,ResourceGroup:resourceGroup}"

if [ ! $? -eq 0 ]
then
    echo "ERROR!"
    exit 1
fi

echo
echo "Retrieving Azure Cosmos DB connection string"
echo "--------------------------------------------"

connectionString=$(az cosmosdb keys list \
    --type connection-strings \
    --name $cosmosAccountName \
    --resource-group $ESHOP_RG \
    --query connectionStrings[0].connectionString \
    --output tsv)

if [ ! $? -eq 0 ]
then
    echo "ERROR!"
    exit 1
fi

echo export ESHOP_COSMOSACCTNAME=$cosmosAccountName >> create-azure-cosmosdb-exports.txt
echo export ESHOP_COSMOSDBCONNSTRING=$connectionString >> create-azure-cosmosdb-exports.txt
echo export ESHOP_IDTAG=$eshopIdTag >> create-azure-cosmosdb-exports.txt

echo export ESHOP_IDTAG=$eshopIdTag >> create-idtag-exports.txt

echo 
echo "ConnectionString: $connectionString" 
echo 

# provisioningState=""

# while [ -z "$provisioningState" ] || [ "$provisioningState" != "Creating" ]
# do
#     provisioningState=$(az redis show -g $ESHOP_RG -n $redisName --query provisioningState -o tsv)

#     if [ ! $? -eq 0 ]
#     then
#         echo "ERROR!"
#         exit 1
#     fi

#     if [ "$provisioningState" == "Creating" ]
#     then
#         echo "Waiting for the Azure Cache for Redis creation to finish ($provisioningState) - Ctrl+C to cancel..."
#         sleep 10
#     else
#         echo "Created Azure Cache for Redis $redisName in RG $ESHOP_RG at location $ESHOP_LOCATION." 
#     fi
# done

echo
echo "Environment variables" 
echo "---------------------" 
cat create-azure-cosmosdb-exports.txt
echo 
echo "Run the following command to update the environment"
echo 'eval $(cat ~/clouddrive/source/create-azure-cosmosdb-exports.txt)'
echo

mv -f create-azure-cosmosdb-exports.txt ~/clouddrive/source/
mv -f create-idtag-exports.txt ~/clouddrive/source/
