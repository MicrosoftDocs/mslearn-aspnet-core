#!/bin/bash

# Hi!
# If you're reading this, you're probably interested in what's 
# going on within this script. We've provided what we hope are useful
# comments inline, as well as color-coded relevant shell output.
# We hope it's useful for you, but if you have any questions or suggestions
# please open an issue on https:/github.com/MicrosoftDocs/learn-aspnet-core.
#

## Start

# Module name
declare moduleName="build-web-api-net-core"
# dotnet SDK version
declare -x dotnetSdkVersion="2.2.401"

# Any other declarations we need
declare -x gitBranch="web-api-setup"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare dotnetBotGreeting="I'm going to configure the .NET Core SDK for you!"

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)