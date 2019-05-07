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

# Any other declarations we need
declare -x gitBranch="create-razor-pages-aspnet-core"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare -x projectRootDirectory="ContosoPets.Api"

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
    text+="if ! [ \$(echo \$PATH | grep ~/.dotnet/tools) ]; then export PATH=\$PATH:~/.dotnet/tools; fi${newline}"
    text+="echo ${newline}"
    text+="cd $srcWorkingDirectory${newline}"
    echo "$text" > ~/$variableScript
    chmod +x ~/$variableScript
}
pushWebApi() {
    (
        echo "${newline}${headingStyle}Deploying ASP.NET Core web API to Azure...${defaultTextStyle}"
        cd $srcWorkingDirectory/$projectRootDirectory
        set -x
        git push --quiet --set-upstream azure master
    )
    echo
}

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)

# Provision stuff here
provisionResourceGroup
provisionAppService
pushWebApi

# Clean up
resetAzureCliDefaults
writeVariablesScript
addVariablesToStartup

# We're done! Summarize.
summarize

# Run the variables script to make sure everything is as expected
. ~/$variableScript