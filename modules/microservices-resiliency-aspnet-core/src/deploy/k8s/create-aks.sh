#!/bin/bash
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
else
    if [ -z "$eshopLocation" ]
    then
        eshopLocation=`az group show -g $eshopRg --query "location" -otsv`
    fi
fi

# AKS Cluster creation

echo
echo "Creating AKS cluster \"$eshopAksName\" in RG \"$eshopRg\" and location \"$eshopLocation\"..."
aksCreateCommand="az aks create -n $eshopAksName -g $eshopRg -c $eshopNodeCount --vm-set-type VirtualMachineScaleSets -l $eshopLocation --enable-managed-identity --generate-ssh-keys -o json"

retry=5
aks=`$aksCreateCommand`
while [ ! $? -eq 0 ]&&[ $retry -gt 0 ]
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

echo
echo "Getting credentials for AKS..."
az aks get-credentials -n $eshopAksName -g $eshopRg --overwrite-existing

# Ingress controller and load balancer (LB) deployment

echo
echo "Installing NGINX ingress controller"
kubectl apply -f ingress-controller/nginx-controller.yaml
kubectl apply -f ingress-controller/nginx-loadbalancer.yaml

echo
echo "Getting Load Balancer public IP"

aksNodeRG=`az aks list --query "[?name=='$eshopAksName'&&resourceGroup=='$eshopRg'].nodeResourceGroup" -otsv`

while [ "$eshopLbIp" == "" ] || [ "$eshopLbIp" == "<pending>" ]
do
    eshopLbIp=`kubectl get svc/ingress-nginx -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
    if [ "$eshopLbIp" == "" ]
    then
        echo "Waiting for the Load Balancer IP address - Ctrl+C to cancel..."
        sleep 5
    else
        echo "Assigned IP address: $eshopLbIp"
    fi
done

echo
echo "NGINX ingress controller installed."

echo export ESHOP_RG=$eshopRg > create-aks-exports.txt
echo export ESHOP_LOCATION=$eshopLocation >> create-aks-exports.txt
echo export ESHOP_AKSNAME=$eshopAksName >> create-aks-exports.txt
echo export ESHOP_AKSNODERG=$aksNodeRG >> create-aks-exports.txt
echo export ESHOP_LBIP=$eshopLbIp >> create-aks-exports.txt

echo
echo "AKS cluster \"$eshopAksName\" created with LB public IP \"$eshopLbIp\"."
echo
echo "Environment variables"
echo "---------------------"
cat create-aks-exports.txt
echo

if [ -z "$ESHOP_QUICKSTART" ]
then
    echo "Run the following command to update the environment"
    echo 'eval $(cat ~/clouddrive/aspnet-learn/create-aks-exports.txt)'
    echo
fi

mv -f create-aks-exports.txt ~/clouddrive/aspnet-learn/
