#!/bin/bash

# Hi!
# If you're reading this, you're probably interested in what's 
# going on within this script. We've provided what we hope are useful
# comments inline, as well as color-coded relevant shell output.
# We hope it's useful for you, but if you have any questions
# please open an issue on https:/github.com/MicrosoftDocs/learn-aspnet-core.

# If the script appears to have already been run, just set the vars and leave.
declare variableScript='variables.sh'
if [ -e ~/$variableScript ]
then
    . ~/$variableScript
    return 1
fi

# Text formatting
declare red=`tput setaf 1`
declare green=`tput setaf 2`
declare yellow=`tput setaf 3`
declare blue=`tput setaf 4`
declare magenta=`tput setaf 5`
declare cyan=`tput setaf 6`
declare white=`tput setaf 7`
declare defaultColor=`tput setaf 9`
declare bold=`tput bold`
declare plain=`tput sgr0`
declare newline=$'\n'

# Check to make sure we're in Azure Cloud Shell
if [ "${AZURE_HTTP_USER_AGENT:0:11}" != "cloud-shell" ]
then
    echo "${bold}${red}WARNING!!!${plain}${white}" \
        "It doesn't appear you are currently running in an instance of Azure Cloud Shell. " \
        "Please only proceed if you know what you are doing and expected this message.${newline}${newline}" \
        "${bold}${green}Do you know what you are doing?${plain}${white}"
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
declare defaultResourceGroupName="EfCoreModule"
declare resourceGroupName=""
declare rgStatus=""

# If there is more than one RG or there's only one but its name is not a GUID,
# we're probably not in the Learn sandbox.
if [[ ! ${existingResourceGroup//-/} =~ ^[[:xdigit:]]{32}$ ]] || [ $resourceGroupCount -gt 1 ]
then
    echo "${bold}${red}WARNING!!!${plain}${white}" \
        "It doesn't appear you are currently running in a Microsoft Learn sandbox." \
        "Using default resource group."
    resourceGroupName=$defaultResourceGroupName
else
    resourceGroupName=$existingResourceGroup
fi

echo "Using Azure resource group ${bold}${cyan}$resourceGroupName${plain}${white}."

# Generate a random number for unique resource names
declare instanceId=$(($RANDOM * $RANDOM))

# Variables
declare gitUrl=https://github.com/MicrosoftDocs/mslearn-aspnet-core
declare gitBranch=persist-data-ef-core
declare srcWorkingDirectory=~/mslearn-aspnet-core/src
declare setupWorkingDirectory=~/mslearn-aspnet-core/setup
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



# Functions
setAzureCliDefaults() {
    echo "${white}Setting default Azure CLI values...${cyan}"
    (
        set -x
        az configure --defaults \
            group=$resourceGroupName \
            location=SouthCentralUs
    )
    echo "${white}"
}
resetAzureCliDefaults() {
    echo "${white}Resetting default Azure CLI values...${cyan}"
    (
        set -x
        az configure --defaults \
            group= \
            location=
    )
    echo "${white}"
}

initEnvironment(){
    # Set location
    cd ~

    # Display installed .NET Core SDK version
    dotnetsdkversion=$(dotnet --version)
    echo "${magenta}${bold}Using .NET Core SDK version $dotnetsdkversion${white}${plain}"

    # Install .NET Core global tool to display connection info
    dotnet tool install dotnetsay --tool-path ~/dotnetsay

    # Greetings!
    greeting="${newline}${white}${bold}Hi there!${plain}${newline}"
    greeting+="I'm going to provision some ${cyan}${bold}Azure${white}${plain} resources${newline}"
    greeting+="and get the code you'll need for this module.${magenta}${bold}"

    ~/dotnetsay/dotnetsay "$greeting"
}

downloadAndBuild() {
    # Set location
    cd ~

    # Set global Git config variables
    git config --global user.name "Microsoft Learn Student"
    git config --global user.email learn@contoso.com
    
    # Download the sample project, restore NuGet packages, and build
    echo "${newline}${white}Downloading code...${yellow}"
    (set -x; git clone --branch $gitBranch $gitUrl --quiet)

    echo "${newline}${white}Building code...${magenta}${bold}"
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
    text+="declare gitUrl=$gitUrl${newline}"
    text+="declare gitBranch=$gitBranch${newline}"
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
    text+="declare apiKey=$(cat ~/$apiKeyTempFile)${newline}"
    text+="declare appId=$(cat ~/$appIdTempFile)${newline}"
    text+="declare instrumentationKey=$(cat ~/$instrumentationKeyTempFile)${newline}"
    text+="alias db=\"sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName\"${newline}"
    text+="echo \"${green}${bold}The following variables are used in this module:\"${newline}"
    text+="echo \"${magenta}${bold}srcWorkingDirectory: ${white}${plain}$srcWorkingDirectory\"${newline}"
    text+="echo \"${magenta}${bold}setupWorkingDirectory: ${white}${plain}$setupWorkingDirectory\"${newline}"
    text+="echo \"${magenta}${bold}sqlConnectionString: ${white}${plain}$sqlConnectionString\"${newline}"
    text+="echo \"${magenta}${bold}sqlUsername: ${white}${plain}$sqlUsername\"${newline}"
    text+="echo \"${magenta}${bold}sqlPassword: ${white}${plain}$sqlPassword\"${newline}"
    text+="echo \"${magenta}${bold}instrumentationKey ${white}${plain}(for Application Insights)${magenta}${bold}: ${white}${plain}$(cat ~/$instrumentationKeyTempFile)\"${newline}"
    text+="echo \"${magenta}${bold}appId ${white}${plain}(for Application Insights)${magenta}${bold}: ${white}${plain}$(cat ~/$appIdTempFile)\"${newline}"
    text+="echo \"${magenta}${bold}apiKey ${white}${plain}(for Application Insights)${magenta}${bold}: ${white}${plain}$(cat ~/$apiKeyTempFile)\"${newline}"
    text+="echo ${newline}"
    text+="echo \"${white}db ${magenta}${bold}is an alias for${white}${plain} sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName\"${newline}"
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
    if [ $resourceGroupName = $defaultResourceGroupName ]
    then
        (
            echo
            echo "${newline}${white}Provisioning Azure Resource Group...${cyan}"
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
        echo "${newline}${white}Provisioning Azure SQL Database Server...${cyan}"
        set -x
        az sql server create \
            --name $sqlServerName \
            --admin-user $sqlUsername \
            --admin-password $sqlPassword \
            --output none
    )
    (
        echo "${newline}${white}Provisioning Azure SQL Database...${cyan}"
        set -x
        az sql db create \
            --name $databaseName \
            --server $sqlServerName \
            --output none
    )
    (
        echo "${newline}${white}Adding Azure IP addresses to Azure SQL Database firewall rules...${cyan}"
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
        echo "${newline}${white}Provisioning Azure Monitor Application Insights...${cyan}"
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

    echo "${newline}${white}Using Azure REST API to set an API Key in Application Insights. The command looks like this (abridged for brevity):"
    echo "${yellow}curl -X POST \\${newline}" \
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

createAliases(){
    echo "${newline}${white}Creating aliases...${yellow}"
    set -x
    alias db="sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName"
    set +x
    echo
}

# Create resources
initEnvironment
downloadAndBuild
setAzureCliDefaults
provisionResourceGroup
provisionDatabase &
provisionAppInsights &
wait &>/dev/null
editSettings
resetAzureCliDefaults
createAliases
writeVariablesScript
cleanupTempFiles

# We're done! Summarize.
summary="${newline}${green}${bold}Your environment is ready!${white}${plain}${newline}"
summary+="I set up some ${cyan}${bold}Azure${white}${plain} resources and downloaded the code you'll need.${newline}"
summary+="You can display this information again by running ${red}${bold}. ~/setup.sh${white}${plain} from any location.${magenta}${bold}"
~/dotnetsay/dotnetsay "$summary"

. ~/$variableScript