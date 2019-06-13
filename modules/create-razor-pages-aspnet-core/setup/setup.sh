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

# dotnet SDK version
declare -x dotnetSdkVersion="2.2.300"

# Any other declarations we need
declare -x gitBranch="create-razor-pages-aspnet-core"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare -x projectRootDirectory="ContosoPets.Api"
declare moduleWorkingDirectory="ContosoPets.Ui"

# If the script appears to have already been run, just set the vars and leave.
declare variableScript='variables.sh'
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
    text+="echo ${newline}"
    text+="cd $srcWorkingDirectory/$moduleWorkingDirectory${newline}"
    text+="code ."
    echo "$text" > ~/$variableScript
    chmod +x ~/$variableScript
}
editSettings(){
    sed -i "s|<web-app-name>|$webAppName|g" $srcWorkingDirectory/$moduleWorkingDirectory/appsettings.json
}

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)
 
# Download and build
downloadAndBuild

# Provision stuff here
setAzureCliDefaults
provisionResourceGroup
provisionAppService

# Clean up
editSettings
writeVariablesScript
addVariablesToStartup

# We're done! Summarize.
summarize

# Run the variables script to make sure everything is as expected
. ~/$variableScript