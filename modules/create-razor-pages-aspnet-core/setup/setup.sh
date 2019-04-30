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
declare moduleName="create-razor-pages-aspnet-core"


declare scriptPath=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts
declare themeScript=$scriptPath/theme.sh
declare initEnvironmentScript=$scriptPath/initenvironment.sh

# If the script appears to have already been run, just set the vars and leave.
declare variableScript='variables.sh'
if [ -e ~/$variableScript ]
then
    . ~/$variableScript
    return 1
fi

# Grab and run themeScript
. <(wget -q -O - $themeScript)

# Check to make sure we're in Azure Cloud Shell
if [ "${AZURE_HTTP_USER_AGENT:0:11}" != "cloud-shell" ]
then
    echo "${bold}${red}WARNING!!!${plain}${white}" \
        "It appears that you're not running this script in an instance of Azure Cloud Shell." \
        "This script was designed for the environment in Azure Cloud Shell, and we can make no promises that it'll function as intended anywhere else." \
        "Please only proceed if you know what you're doing.${newline}${newline}" \
        "${bold}${red}Do you know what you're doing?${plain}${white}"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) echo "${bold}${red}Please let us know that you saw this message using the feedback links provided.${plain}${white}"; return 0;;
        esac
    done
fi

# Figure out the name of the resource group to use
declare resourceGroupCount=$(az group list | jq '. | length')
declare existingResourceGroup=$(az group list | jq '.[0].name' --raw-output)
declare resourceGroupName=""
declare rgStatus=""

# If there is more than one RG or there's only one but its name is not a GUID,
# we're probably not in the Learn sandbox.
if [[ ! ${existingResourceGroup//-/} =~ ^[[:xdigit:]]{32}$ ]] || [ $resourceGroupCount -gt 1 ]
then
    echo "${bold}${red}WARNING!!!${plain}${white}" \
        "It doesn't appear you are currently running in a Microsoft Learn sandbox." \
        "Using default resource group."
    resourceGroupName=$moduleName
else
    resourceGroupName=$existingResourceGroup
fi

echo "Using Azure resource group ${bold}${cyan}$resourceGroupName${plain}${white}."

# Generate a random number for unique resource names
declare instanceId=$(($RANDOM * $RANDOM))

# Variables
declare -x gitBranch=live
declare gitDirectoriesToClone="modules/persist-data-ef-core/setup/ modules/persist-data-ef-core/src/"
declare gitPathToCloneScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/sparsecheckout.sh

declare srcWorkingDirectory=~/contoso-pets/src
declare setupWorkingDirectory=~/contoso-pets/setup
declare gitRepoWorkingDirectory=$srcWorkingDirectory/ContosoPets.Api

declare sqlServerName=sqldb$instanceId
declare sqlHostName=$sqlServerName.database.windows.net
declare sqlUsername=SqlUser
declare sqlPassword=Pass.$RANDOM.word
declare databaseName=ContosoPets
declare sqlConnectionString="Data Source=$sqlServerName.database.windows.net;Initial Catalog=$databaseName;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False"

declare appInsightsName=appinsights$instanceId
declare subscriptionId=$(az account show --query id --output tsv)

declare apiKeyTempFile='apiKey.temp'
declare appIdTempFile='appId.temp'
declare instrumentationKeyTempFile='instrumentationKey.temp'
declare connectFile='connect.txt'

declare dotnetsdkversion=$(dotnet --version)



# Functions
setAzureCliDefaults() {
    echo "${plain}${white}Setting default Azure CLI values...${cyan}${bold}"
    (
        set -x
        az configure --defaults \
            group=$resourceGroupName \
            location=SouthCentralUs
    )
}
resetAzureCliDefaults() {
    echo "${plain}${white}Resetting default Azure CLI values...${cyan}${bold}"
    (
        set -x
        az configure --defaults \
            group= \
            location=
    )
}

configureDotNetCli() {
    echo "${newline}${plain}${white}Configuring the .NET Core CLI..."

    # By default, the .NET Core CLI prints Welcome and Telemetry messages on
    # the first run. Suppress those messages by creating an appropriately
    # named file on disk.
    touch ~/.dotnet/$dotnetsdkversion.dotnetFirstUseSentinel

    # Disable the sending of telemetry to the mothership.
    export DOTNET_CLI_TELEMETRY_OPTOUT=true

    # Add ~/.dotnet/tools to the path so .NET Core Global Tool shims can be found
    if ! [ $(echo $PATH | grep ~/.dotnet/tools) ]; then export PATH=$PATH:~/.dotnet/tools; fi
}

initEnvironment(){

}

downloadAndBuild() {
    # Set location
    cd ~

    # Set global Git config variables
    git config --global user.name "Microsoft Learn Student"
    git config --global user.email learn@contoso.com
    
    # Download the sample project, restore NuGet packages, and build
    echo "${newline}${plain}${white}Downloading code...${blue}${bold}"
    (
        set -x
        curl -s $gitPathToCloneScript | bash -s $gitDirectoriesToClone
    )
    echo "${newline}${plain}${white}Building code...${magenta}${bold}"
    (
        set -x 
        cd $gitRepoWorkingDirectory
        dotnet build --verbosity quiet
    ) 
    echo "${white}${plain}"
}

# Write variables script
writeVariablesScript() {
    text="#!/bin/bash${newline}"
    text+="declare srcWorkingDirectory=$srcWorkingDirectory${newline}"
    text+="declare setupWorkingDirectory=$setupWorkingDirectory${newline}"
    text+="declare gitRepoWorkingDirectory=$gitRepoWorkingDirectory${newline}"
    text+="declare sqlConnectionString=\"$sqlConnectionString\"${newline}"
    text+="declare resourceGroupName=$resourceGroupName${newline}"
    text+="declare subscriptionId=$subscriptionId${newline}"
    text+="echo \"${green}${bold}The following variables are used in this module:\"${newline}"
    text+="echo \"${magenta}${bold}srcWorkingDirectory: ${white}${plain}$srcWorkingDirectory\"${newline}"
    text+="echo \"${magenta}${bold}setupWorkingDirectory: ${white}${plain}$setupWorkingDirectory\"${newline}"
    text+="echo ${newline}"
    text+="echo \"${white}db ${magenta}${bold}is an alias for${white}${plain} sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName\"${newline}"
    text+="if ! [ \$(echo \$PATH | grep ~/.dotnet/tools) ]; then export PATH=\$PATH:~/.dotnet/tools; fi${newline}"
    text+="echo ${newline}"
    text+="cd $srcWorkingDirectory${newline}"
    text+="code .${newline}"
    text+="cd $gitRepoWorkingDirectory${newline}"
    echo "$text" > ~/$variableScript
    chmod 755 ~/$variableScript
}

cleanupTempFiles() {
    rm ~/$apiKeyTempFile
    rm ~/$appIdTempFile
    rm ~/$instrumentationKeyTempFile
}

# Provision Azure Resource Group
provisionResourceGroup() {
    if [ $resourceGroupName -eq $moduleName ]
    then
        (
            echo "${newline}${plain}${white}Provisioning Azure Resource Group...${cyan}${bold}"
            set -x
            az group create \
                --name $resourceGroupName \
                --output none
        )
    fi
}

# Provision Azure SQL Database
provisionDatabase() {
    (
        echo "${newline}${plain}${white}Provisioning Azure SQL Database Server...${cyan}${bold}"
        set -x
        az sql server create \
            --name $sqlServerName \
            --admin-user $sqlUsername \
            --admin-password $sqlPassword \
            --output none
    )
    (
        echo "${newline}${plain}${white}Provisioning Azure SQL Database...${cyan}${bold}"
        set -x
        az sql db create \
            --name $databaseName \
            --server $sqlServerName \
            --output none
    )
    (
        echo "${newline}${plain}${white}Adding Azure IP addresses to Azure SQL Database firewall rules...${cyan}${bold}"
        set -x
        az sql server firewall-rule create \
            --name AllowAzureAccess \
            --start-ip-address 0.0.0.0 \
            --end-ip-address 0.0.0.0 \
            --server $sqlServerName \
            --output none
    )
    echo
}

provisionAppInsights() {
    (
        echo "${newline}${plain}${white}Provisioning Azure Monitor Application Insights...${cyan}${bold}"
        set -x
        az resource create \
            --resource-type microsoft.insights/components \
            --name $appInsightsName \
            --is-full-object \
            --properties '{"kind":"web","location":"southcentralus","properties":{"Application_Type":"web"}}' \
            --output none
    )
    echo

    # Create an API Key for App Insights
    # There is no Az CLI command for this, so we must use the REST API.
    appInsightsDetails=$(az resource show --resource-type microsoft.insights/components --name $appInsightsName)
    token=$(az account get-access-token --output tsv --query accessToken)
    aiPath=$"/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/microsoft.insights/components/$appInsightsName"
    body=$"{\"name\":\"$appInsightsName-ApiKey\",\"linkedReadProperties\":[\"$aiPath/api\"]}"
    len=$(expr length $body)
    url="https://management.azure.com$aiPath/apikeys?api-version=2015-05-01"

    echo "${newline}${plain}${white}Using Azure REST API to set an API Key in Application Insights. The command looks like this (abridged for brevity):"
    echo "${blue}${bold}curl -X POST \\${newline}" \
            "-H \"Authorization: Bearer <token>\" \\${newline}" \
            "-H \"Content-Type: application/json\" \\${newline}" \
            "-H \"Content-Length: <content length>\" \\${newline}" \
            "-s \\${newline}" \
            "<azure management endpoint url> \\${newline}" \
            "-d \"{\\\"name\\\":\\\"<api key name>\\\",\\\"linkedReadProperties\\\":[\\\"<app insights resource uri>/api\\\"]}\"" \
            "${white}"

    result=$(curl -X POST \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -H "Content-Length: $len" \
            -s \
            $url \
            -d $body)
    apiKey=$(echo $result | jq -r '.apiKey')
    appId=$(echo $appInsightsDetails | jq -r '.properties.AppId')
    instrumentationKey=$(echo $appInsightsDetails | jq -r '.properties.InstrumentationKey')

    echo $apiKey > ~/$apiKeyTempFile
    echo $appId > ~/$appIdTempFile
    echo $instrumentationKey > ~/$instrumentationKeyTempFile
}

editSettings(){
    sed -i "s|<instrumentation-key>|$(cat ~/$instrumentationKeyTempFile)|g" $gitRepoWorkingDirectory/appsettings.json
}

addVariablesToStartup(){
    if ! [ $(grep $moduleName .bashrc) ]
    then
        echo "# $moduleName" >> .bashrc
        echo "# Next line added at $(date)" >> .bashrc
        echo ". ~/$variableScript" >> .bashrc
    fi 
}

# Create resources
configureDotNetCli
initEnvironment
downloadAndBuild
setAzureCliDefaults
provisionResourceGroup
provisionDatabase &
wait &>/dev/null
editSettings
resetAzureCliDefaults
writeVariablesScript
addVariablesToStartup
cleanupTempFiles

# We're done! Summarize.
summary="${newline}${green}${bold}Your environment is ready!${white}${plain}${newline}"
summary+="I set up some ${cyan}${bold}Azure${white}${plain} resources and downloaded the code you'll need.${newline}"
summary+="You can resume this session and display this message again by re-running the script.${magenta}${bold}"
dotnetsay "$summary"

. ~/$variableScript