#!/bin/bash

echo
echo "Creating an Azure Cache for Redis instance"
echo "=========================================="

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

redisName=eshop-learn-$eshopIdTag

echo
echo "Creating Azure Cache for Redis $redisName in RG $ESHOP_RG"
echo "------------------------------"

az redis create \
    --location $ESHOP_LOCATION \
    --name $redisName \
    --resource-group $ESHOP_RG \
    --sku Basic \
    --vm-size c0 \
    --query "{Name:name,HotsName:hostName,Location:location,ProvisioningState:provisioningState,RedisVersion:redisVersion}"

if [ ! $? -eq 0 ]
then
    echo "ERROR!"
    exit 1
fi

echo
echo "Retrieving Azure Cache for Redis connection string"
echo "--------------------------------------------------"

primaryKey=$(az redis list-keys \
    --resource-group $ESHOP_RG \
    --name $redisName \
    --query primaryKey \
    --output tsv)

if [ ! $? -eq 0 ]
then
    echo "ERROR!"
    exit 1
fi

connectionString="$redisName.redis.cache.windows.net:6380,password=$primaryKey,ssl=True,abortConnect=False"

echo export ESHOP_REDISNAME=$redisName >> create-azure-redis-exports.txt
echo export ESHOP_REDISPRIMARYKEY=$primaryKey >> create-azure-redis-exports.txt
echo export ESHOP_REDISCONNSTRING=$connectionString >> create-azure-redis-exports.txt
echo export ESHOP_IDTAG=$eshopIdTag >> create-azure-redis-exports.txt

echo export ESHOP_IDTAG=$eshopIdTag >> create-idtag-exports.txt

echo 
echo "ConnectionString: $connectionString" 
echo 

provisioningState=""

while [ -z "$provisioningState" ] || [ "$provisioningState" != "Creating" ]
do
    provisioningState=$(az redis show -g $ESHOP_RG -n $redisName --query provisioningState -o tsv)

    if [ ! $? -eq 0 ]
    then
        echo "ERROR!"
        exit 1
    fi

    if [ "$provisioningState" == "Creating" ]
    then
        echo "Waiting for the Azure Cache for Redis creation to finish ($provisioningState) - Ctrl+C to cancel..."
        sleep 10
    else
        echo "Created Azure Cache for Redis $redisName in RG $ESHOP_RG at location $ESHOP_LOCATION." 
    fi
done

echo
echo "Environment variables" 
echo "---------------------" 
cat create-azure-redis-exports.txt
echo 
echo "Run the following command to update the environment"
echo 'eval $(cat ~/clouddrive/source/create-azure-redis-exports.txt)'
echo

mv -f create-azure-redis-exports.txt ~/clouddrive/source/
mv -f create-idtag-exports.txt ~/clouddrive/source/
