#!/bin/bash

# Hi!
# If you're reading this, you're probably interested in what's 
# going on within this script. We've provided what we hope are useful
# comments inline, as well as color-coded relevant shell output.
# We hope it's useful for you, but if you have any questions or suggestions
# please open an issue on https:/github.com/MicrosoftDocs/mslearn-aspnet-core.
#

## Start

# Module name
declare moduleName="build-web-api-aspnet-core"
# dotnet SDK version
declare -x dotnetSdkVersion="3.1.406"

# Any other declarations we need
declare -x gitBranch="live"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare dotnetBotGreeting="I have configured .NET Core SDK $dotnetSdkVersion. Have fun!"
declare suppressAzureResources=true

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)

# Create and switch to working directory
mkdir ~/aspnet-learn
mkdir ~/aspnet-learn/src
cd ~/aspnet-learn/src

# If they reconnect, bring them back here.
echo >> ~/.bashrc
echo "cd ~/aspnet-learn/src/ContosoPets.Api && code ." >> ~/.bashrc
