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
declare -x moduleName="create-razor-pages-aspnet-core"

# dotnet SDK version
declare -x dotnetSdkVersion="3.1.406"

# Any other declarations we need
declare -x gitBranch="live"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare -x projectRootDirectory="ContosoPets.Ui"

# If the script appears to have already been run, just set the vars and leave.
declare variableScript="variables.sh"
if [ -e ~/$variableScript ]
then
    . ~/$variableScript
    return 1
fi

# Write variables script
writeVariablesScript() {
    text="#!/bin/bash${newline}"
    text+="declare srcWorkingDirectory=$srcWorkingDirectory${newline}"
    text+="declare setupWorkingDirectory=$setupWorkingDirectory${newline}"
    text+="declare resourceGroupName=$resourceGroupName${newline}"
    text+="declare subscriptionId=$subscriptionId${newline}"
    text+="declare webAppName=$webAppName${newline}"
    text+="declare webPlanName=$webPlanName${newline}"
    text+="declare webAppUrl=$webAppUrl${newline}"
    text+="echo \"${headingStyle}The following variable is used in this module:\"${newline}"
    text+="echo \"${headingStyle}webAppUrl: ${defaultTextStyle}$webAppUrl\"${newline}"
    text+="if ! [ \$(echo \$PATH | grep ~/.dotnet/tools) ]; then export PATH=\$PATH:~/.dotnet/tools; fi${newline}"
    text+="echo ${newline}"
    text+="cd $srcWorkingDirectory/$projectRootDirectory${newline}"
    text+="code .${newline}"
    echo "$text" > ~/$variableScript
    chmod +x ~/$variableScript
}
writeAzWebappConfig(){
    mkdir $srcWorkingDirectory/$projectRootDirectory/.azure && pushd $_
    echo "[defaults]" > config
    echo "group = $resourceGroupName" >> config
    echo "sku = FREE" >> config
    echo "appserviceplan = $webPlanName" >> config
    echo "location = $defaultLocation" >> config
    echo "web = $webAppName" >> config
}

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)

# Download
downloadStarterApp

# Provision stuff here
setAzureCliDefaults
provisionResourceGroup
provisionAppServicePlan

(
    # web API
    declare -x webAppName=apiapp$instanceId
    declare -x projectRootDirectory="ContosoPets.Api"
    declare -x webAppLabel="ContosoPets.Api web API"
    provisionAppService

    # Deploy the app because it's a dependency.
    cd $srcWorkingDirectory/$projectRootDirectory
    az webapp up --name $webAppName --plan $webPlanName &> ../apiapp-deploy.log
) &
(
    # web app
    declare -x webAppName=webapp$instanceId
    declare -x projectRootDirectory="ContosoPets.Ui"
    declare -x webAppLabel="ContosoPets.Ui Web App"
    provisionAppService
) &

wait &>/dev/null

# Point the web app to the web API
cd $srcWorkingDirectory/$projectRootDirectory
sed -i "s|<web-app-name>|apiapp$instanceId|g" appsettings.json

# Set up az webapp up
writeAzWebappConfig

# Clean up
writeVariablesScript
addVariablesToStartup

# We're done! Summarize.
summarize

# Run the variables script to make sure everything is as expected
. ~/$variableScript
