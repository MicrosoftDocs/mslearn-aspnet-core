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
declare -x dotnetSdkVersion="6.0.202"

# Module name
declare moduleName="microservices-devops-aspnet-core"

# Any other declarations we need
if ! [ $defaultRegion ]
then
    declare defaultRegion=centralus
fi
declare -x gitBranch="live"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare suppressAzureResources=true
declare rootLocation=~/clouddrive
declare editorHomeLocation=$rootLocation/aspnet-learn/
declare editorHomeLocationTemp=$rootLocation/aspnet-learn-temp/
declare suppressShallowClone=true

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

    # Clone the thing
    # Set location
    cd $rootLocation

    # Make a folder to keep temp files
    mkdir aspnet-learn-temp

    # Set global Git config variables
    git config --global user.name "Microsoft Learn Student"
    git config --global user.email learn@contoso.com

    echo 
    echo "${headingStyle}Please enter the URL of your GitHub repo to clone.${defaultTextStyle}"
    echo "Example: https://github.com/<your username>/mslearn-microservices-devops-aspnet-core" 
    echo
    read -p 'Repo URL: ' repoUrl

    git clone $repoUrl aspnet-learn

    # Set location to ~/clouddrive
    cd $editorHomeLocation

    # Run eshop-learn quickstart to deploy to AKS
    $editorHomeLocation/deploy/k8s/quickstart.sh --resource-group eshop-learn-rg --location $defaultRegion

    # Create ACR resource
    $editorHomeLocation/deploy/k8s/create-acr.sh

    echo "${defaultTextStyle}${newline}${newline}"

    # Display URLs to user
    cat $editorHomeLocationTemp/deployment-urls.txt

    # Display config values for exercise
    cat $editorHomeLocationTemp/config.txt
fi
