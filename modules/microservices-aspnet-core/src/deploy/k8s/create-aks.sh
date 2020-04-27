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
    echo "ERROR: RG is mandatory. Use -g to set it"
    exit 1
fi

if [ -z "$eshopAcrName" ]&&[ -z "$ESHOP_QUICKSTART" ]
then
    echo "ERROR: ACR name is mandatory. Use --acr-name to set it"
    exit 1
fi

if [ ! -z "$eshopSubs" ]
then
    echo "Switching to subs $eshopSubs..."
    az account set -s $eshopSubs
fi

if [ ! $? -eq 0 ]
then
    echo "ERROR: Can't switch to subscription $eshopSubs"
    exit 1
fi

rg=`az group show -g $eshopRg -o json`

if [ -z "$rg" ]
then
    if [ -z "eshopSubs" ]
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
else
    if [ -z "$eshopLocation" ]
    then
        eshopLocation=`az group show -g $eshopRg --query "location" -otsv`
    fi
fi

# Service Principal creation / validation

if [ -z "$eshopClientId" ] || [ -z "$eshopClientSecret" ]
then
    spHomepage="https://eShop-Learn-AKS-SP"$RANDOM
    eshopClientApp=`az ad sp create-for-rbac --name "$spHomepage" --query "[appId,password]" -otsv`

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
echo "Creating AKS cluster \"$eshopAksName\" in RG \"$eshopRg\" and location \"$eshopLocation\"..."
aksCreateCommand="az aks create -n $eshopAksName -g $eshopRg -c $eshopNodeCount --vm-set-type VirtualMachineScaleSets -l $eshopLocation --client-secret $eshopClientSecret --service-principal $eshopClientId --generate-ssh-keys -o json"

retry=5
aks=`$aksCreateCommand`
while [ ! $? -eq 0 ]&&[ $retry -gt 0 ]&&[ ! -z "$spHomepage" ]
do
    echo
    echo "Error creating AKS cluster. Retrying in 5s..."
    let retry--
    sleep 5
    echo
    echo "Retrying AKS cluster creation..."
    aks=`$aksCreateCommand`
done

if [ ! $? -eq 0 ]
then
    echo "ERROR creating AKS cluster!"
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
az aks get-credentials -n $eshopAksName -g $eshopRg

# Ingress controller and load balancer (LB) deployment

echo
echo "Installing NGINX ingress controller"
kubectl apply -f ingress-controller/nginx-mandatory.yaml
kubectl apply -f ingress-controller/nginx-service-loadbalancer.yaml
kubectl apply -f ingress-controller/nginx-cm.yaml

echo
echo "Getting Load Balancer public IP"

k8sLbTag="ingress-nginx/ingress-nginx"
aksNodeRG=`az aks list --query "[?name=='$eshopAksName'&&resourceGroup=='$eshopRg'].nodeResourceGroup" -otsv`

while [ "$eshopLbIp" == "" ]
do
    eshopLbIp=`az network public-ip list -g $aksNodeRG --query "[?tags.service=='$k8sLbTag'].ipAddress" -otsv`
    echo "Waiting for the Load Balancer IP address (Ctrl+C to cancel)..."
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
echo "AKS cluster \"$eshopAksName\" created with LB public IP \"$eshopLbIp\"."
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
    echo 'eval $(cat ~/clouddrive/source/create-aks-exports.txt)'
    echo
fi

mv -f create-aks-exports.txt ~/clouddrive/source/
