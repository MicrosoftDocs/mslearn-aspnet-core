aksRg=${ESHOP_RG}

while [ "$1" != "" ]; do
    case $1 in
        -g | --resource-group)          shift
                                        aksRg=$1
                                        ;;
             * )                        echo "Invalid param: $1"
                                        exit 1
    esac
    shift
done

if [ -z "$aksRg" ]
then
    echo "ERROR: RG is mandatory. Use -g to set it"
    exit 1
fi

echo
echo "Deleting cluster config from kubectl..."
kubectl config delete-cluster eshop-learn-aks

echo
echo "Deleting resource group $aksRg"
az group delete -g $aksRg
