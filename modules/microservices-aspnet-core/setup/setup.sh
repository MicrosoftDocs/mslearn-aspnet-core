#!/bin/bash

# Hi!
# If you're reading this, you're probably interested in what's 
# going on within this script. We've provided what we hope are useful
# comments inline, as well as color-coded relevant shell output.
# We hope it's useful for you, but if you have any questions or suggestions
# please open an issue on https:/github.com/MicrosoftDocs/mslearn-aspnet-core.
#

## Start
cd ~

# dotnet SDK version
declare -x dotnetSdkVersion="3.1.300"

# Module name
declare moduleName="microservices-aspnet-core"

# Any other declarations we need
declare -x gitBranch="live"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare suppressAzureResources=true
declare rootLocation=~/clouddrive
declare editorHomeLocation=$rootLocation/aspnet-learn/src

if [ -d "$rootLocation/aspnet-learn" ]; then
    echo "$rootLocation/aspnet-learn/ already exists!"
    echo " "
    echo "Before running this script, please remove or rename the existing $rootLocation/aspnet-learn/ directory as follows:"
    echo "Remove: rm -r $rootLocation/aspnet-learn/"
    echo "Rename: mv $rootLocation/aspnet-learn/ ~/clouddrive/new-name-here/ "
    echo " "
else
    # Backup .bashrc
    cp ~/.bashrc ~/.bashrc.bak.$moduleName

    # Grab and run initenvironment.sh
    . <(wget -q -O - $initScript)

    # Download
    downloadStarterApp

    # Set location to ~/clouddrive
    cd $editorHomeLocation

    # Launch editor so the user can see the code
    code .

    # Enable aks-preview
    # Mitigation for https://github.com/Azure/azure-cli/issues/14915
    echo "Enabling Azure CLI aks-preview extension..."
    az extension add --name aks-preview --only-show-errors
    echo 

    # Run eshop-learn quickstart to deploy to AKS
    $editorHomeLocation/deploy/k8s/quickstart.sh --resource-group eshop-learn-rg --location westus

    # Disabling the aks-preview we just enabled...
    echo
    echo "Disabling Azure CLI aks-preview extension..."
    az extension remove --name aks-preview --only-show-errors

    # Create ACR resource
    $editorHomeLocation/deploy/k8s/create-acr.sh

    # Display URLs to user
    cat ~/clouddrive/aspnet-learn/deployment-urls.txt
fi

