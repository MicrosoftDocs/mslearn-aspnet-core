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
declare moduleName="persist-data-ef-core"

# Any other declarations we need
declare -x gitBranch="patch"
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
    text+="declare gitRepoWorkingDirectory=$gitRepoWorkingDirectory${newline}"
    text+="declare sqlServerName=$sqlServerName${newline}"
    text+="declare sqlHostName=$sqlHostName${newline}"
    text+="declare sqlUsername=$sqlUsername@$sqlServerName${newline}"
    text+="declare sqlPassword=$sqlPassword${newline}"
    text+="declare databaseName=$databaseName${newline}"
    text+="declare sqlConnectionString=\"$sqlConnectionString\"${newline}"
    text+="declare resourceGroupName=$resourceGroupName${newline}"
    text+="declare appInsightsName=$appInsightsName${newline}"
    text+="declare subscriptionId=$subscriptionId${newline}"
    text+="declare apiKey=$(cat $apiKeyTempFile)${newline}"
    text+="declare appId=$(cat $appIdTempFile)${newline}"
    text+="declare instrumentationKey=$(cat $instrumentationKeyTempFile)${newline}"
    text+="alias db=\"sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName\"${newline}"
    text+="echo \"${headingStyle}The following variables are used in this module:\"${newline}"
    text+="echo \"${headingStyle}srcWorkingDirectory: ${defaultTextStyle}$srcWorkingDirectory\"${newline}"
    text+="echo \"${headingStyle}setupWorkingDirectory: ${defaultTextStyle}$setupWorkingDirectory\"${newline}"
    text+="echo \"${headingStyle}sqlConnectionString: ${defaultTextStyle}$sqlConnectionString\"${newline}"
    text+="echo \"${headingStyle}sqlUsername: ${defaultTextStyle}$sqlUsername\"${newline}"
    text+="echo \"${headingStyle}sqlPassword: ${defaultTextStyle}$sqlPassword\"${newline}"
    text+="echo \"${headingStyle}instrumentationKey ${defaultTextStyle}(for Application Insights)${headingStyle}: ${defaultTextStyle}$(cat $instrumentationKeyTempFile)\"${newline}"
    text+="echo \"${headingStyle}appId ${defaultTextStyle}(for Application Insights)${headingStyle}: ${defaultTextStyle}$(cat $appIdTempFile)\"${newline}"
    text+="echo \"${headingStyle}apiKey ${defaultTextStyle}(for Application Insights)${headingStyle}: ${defaultTextStyle}$(cat $apiKeyTempFile)\"${newline}"
    text+="echo ${newline}"
    text+="echo \"${defaultTextStyle}db ${headingStyle}is an alias for${defaultTextStyle} sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName\"${newline}"
    text+="if ! [ \$(echo \$PATH | grep ~/.dotnet/tools) ]; then export PATH=\$PATH:~/.dotnet/tools; fi${newline}"
    text+="echo ${newline}"
    text+="cd $srcWorkingDirectory/$projectRootDirectory${newline}"
    text+="code ..${newline}"
    echo "$text" > ~/$variableScript
    chmod 755 ~/$variableScript
}

editSettings(){
    sed -i "s|<instrumentation-key>|$(cat $instrumentationKeyTempFile)|g" $srcWorkingDirectory/$projectRootDirectory/appsettings.json
}

createAliases(){
    echo "${newline}${headingStyle}Creating aliases...${defaultTextStyle}"
    set -x
    alias db="sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName"
    set +x
    echo
}

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)

# Provision stuff here
provisionResourceGroup
provisionAzSqlDatabase &
provisionAppInsights &
wait &>/dev/null

# Clean up
editSettings
createAliases
writeVariablesScript
addVariablesToStartup
cleanupTempFiles

# Switch to working directory and launch Cloud Shell Editor
# Open the parent directory in the file explorer
cd $srcWorkingDirectory/$projectRootDirectory
code .. 

# We're done! Summarize.
summarize

# Run the variables script to make sure everything is as expected
. ~/$variableScript
