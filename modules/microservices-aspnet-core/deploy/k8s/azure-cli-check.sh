echo "Making sure you're signed in to Azure CLI..."
az account show -o none

if [ ! $? -eq 0 ]
then
    exit 1
fi

echo "Using the following Azure subscription. If this isn't correct, press Ctrl+C and select the correct subscription with \"az account set\""
echo "${newline}"
az account show -o table
echo "${newline}"
