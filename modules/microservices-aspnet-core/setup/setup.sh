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
declare -x dotnetSdkVersion="6.0.100-preview.7"

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

    # Run eshop-learn quickstart to deploy to AKS
    $editorHomeLocation/deploy/k8s/quickstart.sh --resource-group eshop-learn-rg --location westus

    # Create ACR resource
    $editorHomeLocation/deploy/k8s/create-acr.sh

    # Display URLs to user
    cat ~/clouddrive/aspnet-learn/deployment-urls.txt
fi

