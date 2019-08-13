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
declare -x moduleName="create-razor-pages-aspnet-core"

<<<<<<< HEAD
# Any other declarations we need
declare -x gitBranch="create-razor-pages-aspnet-core"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare -x projectRootDirectory="ContosoPets.Api"
=======
# dotnet SDK version
declare -x dotnetSdkVersion="2.2.401"

# Any other declarations we need
declare -x gitBranch="create-razor-pages-aspnet-core"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare -x projectRootDirectory="ContosoPets.Ui"
>>>>>>> origin/create-razor-pages-aspnet-core

# If the script appears to have already been run, just set the vars and leave.
declare variableScript='variables.sh'
if [ -e ~/$variableScript ]
then
    . ~/$variableScript
    return 1
fi

<<<<<<< HEAD
=======

>>>>>>> origin/create-razor-pages-aspnet-core
# Write variables script
writeVariablesScript() {
    text="#!/bin/bash${newline}"
    text+="declare srcWorkingDirectory=$srcWorkingDirectory${newline}"
    text+="declare setupWorkingDirectory=$setupWorkingDirectory${newline}"
<<<<<<< HEAD
    text+="declare subscriptionId=$subscriptionId${newline}"
    text+="declare resourceGroupName=$resourceGroupName${newline}"
    text+="declare razorAppName=razorapp$instanceId${newline}"
    text+="echo \"${headingStyle}The following variables are used in this module:\"${newline}"
    text+="echo \"${headingStyle}srcWorkingDirectory: ${defaultTextStyle}$srcWorkingDirectory\"${newline}"
    text+="echo \"${headingStyle}setupWorkingDirectory: ${defaultTextStyle}$setupWorkingDirectory\"${newline}"
    text+="echo \"${headingStyle}resourceGroupName: ${defaultTextStyle}$resourceGroupName\"${newline}"
    text+="echo \"${headingStyle}razorAppName: ${defaultTextStyle}razorapp$instanceId\"${newline}"
    text+="echo ${newline}"
    text+="echo \"${headingStyle}Your API URL is: ${defaultTextStyle}https://$webAppName.azurewebsites.net/api/products\"${newline}"
    text+="echo ${newline}"
    text+="if ! [ \$(echo \$PATH | grep ~/.dotnet/tools) ]; then export PATH=\$PATH:~/.dotnet/tools; fi${newline}"
    text+="echo ${newline}"
    text+="cd $srcWorkingDirectory${newline}"
    echo "$text" > ~/$variableScript
    chmod +x ~/$variableScript
}

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)

# Provision stuff here
provisionResourceGroup
provisionAppService
=======
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
 
# Download and build
downloadAndBuild

# Provision stuff here
setAzureCliDefaults
provisionResourceGroup
provisionAppServicePlan

(
    # API web app
    declare -x webAppName=apiapp$instanceId
    declare -x projectRootDirectory="ContosoPets.Api"
    declare -x webAppLabel="ContosoPets.Api API"
    provisionAppService

    # Deploy the app because it's a dependency.
    cd $srcWorkingDirectory/$projectRootDirectory
    az webapp up --name $webAppName --plan $webPlanName &> ../apiapp-deploy.log
) &
(   
    # UI web app
    declare -x webAppName=webapp$instanceId
    declare -x projectRootDirectory="ContosoPets.Ui"
    declare -x webAppLabel="ContosoPets.Ui Web App"
    provisionAppService
) &

wait &>/dev/null

# Point to the Web to the API
cd $srcWorkingDirectory/$projectRootDirectory
sed -i "s|<web-app-name>|apiapp$instanceId|g" appsettings.json

# Setup az webapp up
writeAzWebappConfig
>>>>>>> origin/create-razor-pages-aspnet-core

# Clean up
writeVariablesScript
addVariablesToStartup

# We're done! Summarize.
summarize

# Run the variables script to make sure everything is as expected
<<<<<<< HEAD
. ~/$variableScript
=======
. ~/$variableScript
>>>>>>> origin/create-razor-pages-aspnet-core
