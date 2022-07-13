#!/bin/bash

# Color theming
if [ -f ~/clouddrive/aspnet-learn/setup/theme.sh ]
then
  . <(cat ~/clouddrive/aspnet-learn/setup/theme.sh)
fi

eshopSubs=${ESHOP_SUBS}
eshopRg=${ESHOP_RG}
eshopLocation=${ESHOP_LOCATION}
eshopNodeCount=${ESHOP_NODECOUNT:-1}
eshopAksName=${ESHOP_AKSNAME:-eshop-learn-aks}

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
    echo "${newline}${errorStyle}ERROR: Resource group is mandatory. Use -g to set it.${defaultTextStyle}${newline}"
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
    if [ -z "$eshopLocation" ]
    then
        echo "${newline}${errorStyle}ERROR: If resource group has to be created, location is mandatory. Use -l to set it.${defaultTextStyle}${newline}"
        exit 1
    fi
    echo "Creating resource group \"$eshopRg\" in location \"$eshopLocation\"..."
    echo "${newline} > ${azCliCommandStyle}az group create -n $eshopRg -l $eshopLocation --output none${defaultTextStyle}${newline}"
    az group create -n $eshopRg -l $eshopLocation --output none
    if [ ! $? -eq 0 ]
    then
        echo "${newline}${errorStyle}ERROR: Can't create resource group!${defaultTextStyle}${newline}"
        exit 1
    fi
else
    if [ -z "$eshopLocation" ]
    then
        eshopLocation=`az group show -g $eshopRg --query "location" -otsv`
    fi
fi

# AKS Cluster creation
# Swallow STDERR so we don't get red text here from expected error if the RG doesn't exist
exec 3>&2
exec 2> /dev/null

existingAks=`az aks show -n $eshopAksName -g $eshopRg -o json`

# Reset STDERR
exec 2>&3

if [ -z "$existingAks" ]
then
    echo
    echo "Creating AKS cluster \"$eshopAksName\" in resource group \"$eshopRg\" and location \"$eshopLocation\"..."
    aksCreateCommand="az aks create -n $eshopAksName -g $eshopRg -c $eshopNodeCount --node-vm-size Standard_D2_v3 --vm-set-type VirtualMachineScaleSets -l $eshopLocation --enable-managed-identity --generate-ssh-keys -o json"
    echo "${newline} > ${azCliCommandStyle}$aksCreateCommand${defaultTextStyle}${newline}"
    retry=5
    aks=`$aksCreateCommand`
    while [ ! $? -eq 0 ]&&[ $retry -gt 0 ]
    do
        echo
        echo "Unable to create AKS cluster. Retrying in 5s..."
        let retry--
        sleep 5
        echo
        echo "Retrying AKS cluster creation..."
        aks=`$aksCreateCommand`
    done

    if [ ! $? -eq 0 ]
    then
        echo "${newline}${errorStyle}Error creating AKS cluster!${defaultTextStyle}${newline}"
        exit 1
    fi

    echo
    echo "AKS cluster created."
else
    echo
    echo "Reusing existing AKS resource."
fi

echo
echo "Getting credentials for AKS..."
az aks get-credentials -n $eshopAksName -g $eshopRg --overwrite-existing

# Ingress controller and load balancer (LB) deployment

echo
echo "Installing Nginx ingress controller..."
kubectl apply -f ingress-controller/nginx-controller.yaml

echo
echo "Getting Load Balancer public IP..."

while [ "$eshopLbIp" == "" ] || [ "$eshopLbIp" == "<pending>" ]
do
    eshopLbIp=`kubectl get svc/ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
    if [ "$eshopLbIp" == "" ]
    then
        echo "Waiting for the Load Balancer IP address - Ctrl+C to cancel..."
        sleep 5
    else
        echo "Assigned IP address: $eshopLbIp"
    fi
done

echo
echo "Nginx ingress controller installed."

echo
echo "Wait until ingress is ready to process requests"

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo export ESHOP_RG=$eshopRg > create-aks-exports.txt
echo export ESHOP_LOCATION=$eshopLocation >> create-aks-exports.txt
echo export ESHOP_AKSNAME=$eshopAksName >> create-aks-exports.txt
echo export ESHOP_AKSNODERG=$aksNodeRG >> create-aks-exports.txt
echo export ESHOP_LBIP=$eshopLbIp >> create-aks-exports.txt

if [ -z "$ESHOP_QUICKSTART" ]
then
    echo "Run the following command to update the environment"
    echo 'eval $(cat ~/clouddrive/aspnet-learn/create-aks-exports.txt)'
    echo
fi

mv -f create-aks-exports.txt ~/clouddrive/aspnet-learn/
