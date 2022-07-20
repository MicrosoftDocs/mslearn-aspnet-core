#!/bin/bash
vmSize=Standard_D2_v5

# Color theming
if [ -f ../../../../infrastructure/scripts/theme.sh ]
then
  . <(cat ../../../../infrastructure/scripts/theme.sh)
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
    echo "Creating AKS cluster \"$eshopAksName\" in resource group \"$eshopRg\" and location \"$eshopLocation\"."
    echo "Using VM size \"$vmSize\". You can change this by modifying the value of the \"vmSize\" variable at the top of \"create-aks.sh\""
    aksCreateCommand="az aks create -n $eshopAksName -g $eshopRg -c $eshopNodeCount --node-vm-size $vmSize --vm-set-type VirtualMachineScaleSets -l $eshopLocation --enable-managed-identity --generate-ssh-keys -o json"
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

while [ -z "$eshopLbIp" ]
do
    eshopLbIpCommand="kubectl get svc -n ingress-nginx -o json | jq -r -e '.items[0].status.loadBalancer.ingress[0].ip // empty'"
    echo "${newline} > ${genericCommandStyle}$eshopLbIpCommand${defaultTextStyle}${newline}"
    eshopLbIp=$(eval $eshopLbIpCommand)
    if [ -z "$eshopLbIp" ]
    then
        echo "Load balancer wasn't ready. If this takes more than a minute or two, something is probably wrong. Trying again in 5 seconds..."
        sleep 5
    fi
done

echo "Load balancer IP is $eshopLbIp"

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

mv -f create-aks-exports.txt ../../
