#!/bin/bash
eshopSubs=${ESHOP_SUBS}
eshopRg=${ESHOP_RG}
eshopLocation=${ESHOP_LOCATION}
eshopNodeCount=${ESHOP_NODECOUNT:-1}
eshopRegistry=${ESHOP_REGISTRY}
eshopAcrName=${ESHOP_ACRNAME}
eshopClientId=${ESHOP_CLIENTID}
eshopClientSecret=${ESHOP_CLIENTSECRET}

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
             --acr-name)                shift
                                        eshopAcrName=$1
                                        ;;
             --appid)                   shift
                                        eshopClientId=$1
                                        ;;
             --password)                shift
                                        eshopClientSecret=$1
                                        ;;
             * )                        echo "Invalid param: $1"
                                        exit 1
    esac
    shift
done

if [ -z "$eshopRg" ]
then
    echo "ERROR: resource group is mandatory. Use -g to set it"
    exit 1
fi

if [ -z "$eshopAcrName" ]&&[ -z "$ESHOP_QUICKSTART" ]
then
    echo "ERROR: ACR name is mandatory. Use --acr-name to set it"
    exit 1
fi

if [ ! -z "$eshopSubs" ]
then
    echo "Switching to subscription $eshopSubs..."
    az account set -s $eshopSubs
fi

if [ ! $? -eq 0 ]
then
    echo "ERROR: Can't switch to subscription $eshopSubs"
    exit 1
fi

# Swallow STDERR so we don't get red text here from expected error if the RG doesn't exist
exec 3>&2
exec 2> /dev/null

rg=`az group show -g $eshopRg -o json`

# Reset STDERR
exec 2>&3

if [ -z "$rg" ]
then
    if [ -z "eshopSubs" ]
    then
        echo "ERROR: If resource group has to be created, location is mandatory. Use -l to set it."
        exit 1
    fi
    echo "Creating resource group $eshopRg in location $eshopLocation..."
    echo "> az group create -n $eshopRg -l $eshopLocation --output none"
    az group create -n $eshopRg -l $eshopLocation --output none
    if [ ! $? -eq 0 ]
    then
        echo "ERROR: Can't create resource group"
        exit 1
    fi
else
    if [ -z "$eshopLocation" ]
    then
        eshopLocation=`az group show -g $eshopRg --query "location" -otsv`
    fi
fi

# Service Principal creation / validation

if [ -z "$eshopClientId" ] || [ -z "$eshopClientSecret" ]
then
    echo "Creating service principal..."

    spHomepage="https://eShop-Learn-AKS-SP"$RANDOM
    eshopClientAppCommand="az ad sp create-for-rbac --name "$spHomepage" --query "[appId,password]" -otsv"

    echo "> $eshopClientAppCommand"
    eshopClientApp=`$eshopClientAppCommand`
    
    if [ ! $? -eq 0 ]
    then
        echo "ERROR: Can't create service principal for AKS"
        exit 1
    fi

    eshopClientId=`echo "$eshopClientApp" | head -1`
    eshopClientSecret=`echo "$eshopClientApp" | tail -1`

    if [ "$eshopClientId" == "" ]||[ "$eshopClientSecret" == "" ]
    then
        echo "ERROR: ClientId (\"$eshopClientId\") or ClientSecret (\"$eshopClientSecret\") missing!"
        exit 1
    fi

    echo
    echo "Service principal \"$spHomepage\" created with ID \"$eshopClientId\" and password \"$eshopClientSecret\""
fi

# AKS Cluster creation

eshopAksName="eshop-learn-aks"

echo
echo "Creating AKS cluster \"$eshopAksName\" in resource group \"$eshopRg\" and location \"$eshopLocation\"..."
aksCreateCommand="az aks create -n $eshopAksName -g $eshopRg --node-count $eshopNodeCount --node-vm-size Standard_D2_v3 --vm-set-type VirtualMachineScaleSets -l $eshopLocation --client-secret $eshopClientSecret --service-principal $eshopClientId --generate-ssh-keys -o json"
echo "> $aksCreateCommand"
retry=5
aks=`$aksCreateCommand`
while [ ! $? -eq 0 ]&&[ $retry -gt 0 ]&&[ ! -z "$spHomepage" ]
do
    echo
    echo "New service principal is not yet ready for AKS cluster creation. This is normal and expected. Retrying in 5s..."
    let retry--
    sleep 5
    echo
    echo "Retrying AKS cluster creation..."
    aks=`$aksCreateCommand`
done

if [ ! $? -eq 0 ]
then
    echo "Error creating AKS cluster!"
    exit 1
fi

echo
echo "AKS cluster created."

if [ ! -z "$eshopAcrName" ]
then
    echo
    echo "Granting AKS pull permissions from ACR $eshopAcrName"
    az aks update -n $eshopAksName -g $eshopRg --attach-acr $eshopAcrName
fi

echo
echo "Getting credentials for AKS..."
az aks get-credentials -n $eshopAksName -g $eshopRg --overwrite-existing

# Ingress controller and load balancer (LB) deployment

echo
echo "Installing NGINX ingress controller"
kubectl apply -f ingress-controller/nginx-mandatory.yaml
kubectl apply -f ingress-controller/nginx-service-loadbalancer.yaml
kubectl apply -f ingress-controller/nginx-cm.yaml

echo
echo "Getting load balancer public IP"

k8sLbTag="ingress-nginx/ingress-nginx"
aksNodeRGCommand="az aks list --query \"[?name=='$eshopAksName'&&resourceGroup=='$eshopRg'].nodeResourceGroup\" -otsv"

retry=5
echo "> $aksNodeRGCommand"
aksNodeRG=$(eval $aksNodeRGCommand)
while [ "$aksNodeRG" == "" ]
do
    echo
    echo "Unable to obtain load balancer resource group. Retrying in 5s..."
    let retry--
    sleep 5
    echo
    echo "Retrying..."
    echo $aksNodeRGCommand
    aksNodeRG=$(eval $aksNodeRGCommand)
done


while [ "$eshopLbIp" == "" ]
do
    eshopLbIpCommand="az network public-ip list -g $aksNodeRG --query \"[?tags.service=='$k8sLbTag'].ipAddress\" -otsv"
    echo "> $eshopLbIpCommand"
    eshopLbIp=$(eval $eshopLbIpCommand)
    echo "Waiting for the load balancer IP address (Ctrl+C to cancel)..."
    sleep 5
done

echo
echo "NGINX ingress controller installed."

if [ "$spHomepage" != "" ]
then
    echo
    echo "Service principal $spHomepage created with ID \"$eshopClientId\" and password \"$eshopClientSecret\""
fi

echo export ESHOP_SUBS=$eshopSubs > create-aks-exports.txt
echo export ESHOP_RG=$eshopRg >> create-aks-exports.txt
echo export ESHOP_LOCATION=$eshopLocation >> create-aks-exports.txt

if [ ! -z "$eshopAcrName" ]
then
    echo export ESHOP_ACRNAME=$eshopAcrName >> create-aks-exports.txt
fi

if [ ! -z "$eshopRegistry" ]
then
    echo export ESHOP_REGISTRY=$eshopRegistry >> create-aks-exports.txt
fi

if [ "$spHomepage" != "" ]
then
    echo export ESHOP_CLIENTID=$eshopClientId >> create-aks-exports.txt
    echo export ESHOP_CLIENTPASSWORD=$eshopClientSecret >> create-aks-exports.txt
fi

echo export ESHOP_LBIP=$eshopLbIp >> create-aks-exports.txt

echo
echo "AKS cluster \"$eshopAksName\" created with load balancer public IP \"$eshopLbIp\"."
echo
echo "Environment variables"
echo "---------------------"
cat create-aks-exports.txt
echo
echo "Commands:"
echo
echo "- To deploy eShop to AKS: ./deploy-aks.sh --acr $eshopRegistry --ip $eshopLbIp"
echo

if [ -z "$ESHOP_QUICKSTART" ]
then
    echo "Run the following command to update the environment"
    echo 'eval $(cat ~/clouddrive/aspnet-learn/create-aks-exports.txt)'
    echo
fi

mv -f create-aks-exports.txt ~/clouddrive/aspnet-learn/
