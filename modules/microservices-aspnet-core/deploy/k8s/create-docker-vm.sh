eshopSubs=${ESHOP_SUBS}
eshopRg=${ESHOP_RG}
eshopLocation=${ESHOP_LOCATION}
eshopIdTag=${ESHOP_IDTAG}

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

# Docker VM creation

echo
echo "Creating Docker VM..."

if [ -z "$eshopIdTag" ]
then
    dateString=$(date "+%Y%m%d%H%M%S")
    random=`head /dev/urandom | tr -dc 0-9 | head -c 3 ; echo ''`

    eshopIdTag="$dateString$random"
fi

eshopDockerVm="docker-vm-$eshopIdTag"

docker-machine create \
    --driver azure \
    --azure-subscription-id $eshopSubs \
    --azure-location "$eshopLocation" \
    --azure-resource-group "$eshopRg" \
    --azure-image  "Canonical:UbuntuServer:18.04-LTS:latest" \
    --azure-size "Standard_B2s" \
    --azure-open-port 8080 \
    "$eshopDockerVm"

echo
echo "Docker VM created."

echo export ESHOP_IDTAG=$eshopIdTag > create-docker-vm-exports.txt
echo export ESHOP_DOCKERVM=$eshopDockerVm >> create-docker-vm-exports.txt
docker-machine env $eshopDockerVm --shell bash | grep export >> create-docker-vm-exports.txt

echo
echo "Making the Docker VM available on the Azure Cloud Shell..."
eval $(docker-machine env $eshopDockerVm --shell bash) >> ~/.bashrc

echo 
echo "Created VM \"$eshopDockerVm\"." 
echo 
echo "Environment variables" 
echo "---------------------" 
cat create-docker-vm-exports.txt

echo
echo "Run the following commands to update the environment"
echo 'eval $(cat ~/clouddrive/source/create-docker-vm-exports.txt)'
echo "source ~/.bashrc"
echo

mv -f create-docker-vm-exports.txt ~/clouddrive/source/
