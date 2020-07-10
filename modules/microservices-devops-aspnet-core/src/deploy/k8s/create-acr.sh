#!/bin/bash

if [ -f ~/clouddrive/source/create-aks-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-aks-exports.txt)
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
    echo "ERROR: RG is mandatory. Use -g to set it"
    exit 1
fi

rg=`az group show -g $eshopRg -o json`

if [ -z "$rg" ]
then
    if [ -z "$eshopLocation" ]
    then
        echo "ERROR: If RG has to be created, location is mandatory. Use -l to set it."
        exit 1
    fi
    echo "Creating RG $eshopRg in location $eshopLocation..."
    az group create -n $eshopRg -l $eshopLocation
    if [ ! $? -eq 0 ]
    then
        echo "ERROR: Can't create Resource Group"
        exit 1
    fi

    echo "Created RG \"$eshopRg\" in location \"$eshopLocation\"."

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
    echo "Creating ACR eshoplearn$eshopIdTag in RG $eshopRg"
    eshopAcrName=`az acr create --name eshoplearn$eshopIdTag -g $eshopRg -l $eshopLocation -o json --sku standard --admin-enabled --query "name" -otsv`

    if [ ! $? -eq 0 ]
    then
        echo "ERROR creating ACR!"
        exit 1
    fi

    echo ACR created
    echo
fi

eshopRegistry=`az acr show -n $eshopAcrName --query "loginServer" -otsv`

if [ -z "$eshopRegistry" ]
then
    echo "ERROR ACR server $eshopAcrName doesn't exist!"
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

echo export ESHOP_RG=$eshopRg > create-acr-exports.txt
echo export ESHOP_LOCATION=$eshopLocation >> create-acr-exports.txt
echo export ESHOP_AKSNAME=$ESHOP_AKSNAME >> create-acr-exports.txt
echo export ESHOP_LBIP=$ESHOP_LBIP >> create-acr-exports.txt
echo export ESHOP_ACRNAME=$eshopAcrName >> create-acr-exports.txt
echo export ESHOP_REGISTRY=$eshopRegistry >> create-acr-exports.txt
echo export ESHOP_ACRUSER=$eshopAcrUser >> create-acr-exports.txt
echo export ESHOP_ACRPASSWORD=$eshopAcrPassword >> create-acr-exports.txt
echo export ESHOP_IDTAG=$eshopIdTag >> create-acr-exports.txt

echo 
echo "Created ACR \"$eshopAcrName\" in RG \"$eshopRg\" in location \"$eshopLocation\"." 
echo 
echo "Login server: $eshopRegistry" 
echo "User Login: $eshopAcrUser" 
echo "Password: $eshopAcrPassword" 
echo 
echo "Environment variables" 
echo "---------------------" 
cat create-acr-exports.txt
echo 
echo "Commands" 
echo "--------" 
echo "- To login Docker to ACR: docker login $eshopRegistry -u $eshopAcrUser -p $eshopAcrPassword" 
echo 
echo "Run the following command to update the environment"
echo 'eval $(cat ~/clouddrive/source/create-acr-exports.txt)'
echo

mv -f create-acr-exports.txt ~/clouddrive/source/
