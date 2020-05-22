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

# Module name
declare moduleName="microservices-aspnet-core"

# Any other declarations we need
declare -x gitBranch="microservices-aspnet-core"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare dotnetBotGreeting="I'm going to download and deploy your microservices app!"
declare suppressAzureResources=true
declare suppressConfigureDotNet=true
declare rootLocation=~/clouddrive
declare editorHomeLocation=$rootLocation/aspnet-learn/src

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)

# Download and build
downloadAndBuild

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