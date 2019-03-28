#!/bin/bash
# If the script has already been run, just set the vars and leave.
declare variableScript='variables.sh'
if [ -e ~/$variableScript ]
then
    . ~/$variableScript
    return 1
fi

# Generate a random number for unique resource names
declare instanceId=$(($RANDOM * $RANDOM))

# Variables
declare gitUrl=https://github.com/MicrosoftDocs/mslearn-aspnet-core
declare gitBranch=persist-data-ef-core
declare srcWorkingDirectory=~/mslearn-aspnet-core/src
declare gitRepoWorkingDirectory=$srcWorkingDirectory/ContosoPets.Api

declare sqlServerName=sqldb$instanceId
declare sqlHostName=$sqlServerName.database.windows.net
declare sqlUsername=SqlUser
declare sqlPassword=Pass.$RANDOM.word
declare databaseName=ContosoPets
declare sqlConnectionString="Data Source=$sqlServerName.database.windows.net;Initial Catalog=$databaseName;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False"
declare resourceGroupName=EfCoreModule

declare appInsightsName=appinsights$instanceId
declare subscriptionId=$(az account show --query id --output tsv)

declare apiKeyTempFile='apiKey.temp'
declare appIdTempFile='appId.temp'
declare instrumentationKeyTempFile='instrumentationKey.temp'
declare connectFile='connect.txt'

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
    echo "${magenta}Using .NET Core SDK version $dotnetsdkversion${white}"

    # Install .NET Core global tool to display connection info
    dotnet tool install dotnetsay --tool-path ~/dotnetsay

    # Greetings!
    greeting="${newline}${white}${bold}Hi there!${plain}${newline}"
    greeting+="I'm going to set up some ${cyan}${bold}Azure${white}${plain} resources${newline}"
    greeting+="and get the code you'll need for this module.${magenta}"

    ~/dotnetsay/dotnetsay "$greeting"
    
    echo "${green}${bold}Deployment tasks run asynchronously from here on.${white}${plain}"
}

downloadAndBuild() {
    # Set location
    cd ~

    # Set global Git config variables
    git config --global user.name "Microsoft Learn Student"
    git config --global user.email learn@contoso.com
    
    # Download the sample project, restore NuGet packages, and build
    echo "${white}Downloading code...${yellow}"
    (set -x; git clone --branch $gitBranch $gitUrl --quiet)

    echo "${white}Building code...${magenta}"
    (
        set -x 
        cd $gitRepoWorkingDirectory
        dotnet build --verbosity quiet
    ) 
}

# Write variables script
writeVariablesScript() {
    text="#!/bin/bash${newline}"
    text+="declare gitUrl=$gitUrl${newline}"
    text+="declare gitBranch=$gitBranch${newline}"
    text+="declare srcWorkingDirectory=$srcWorkingDirectory${newline}"
    text+="declare gitRepoWorkingDirectory=$gitRepoWorkingDirectory${newline}"
    text+="declare sqlServerName=$sqlServerName${newline}"
    text+="declare sqlHostName=$sqlHostName${newline}"
    text+="declare sqlUsername=$sqlUsername${newline}"
    text+="declare sqlPassword=$sqlPassword${newline}"
    text+="declare databaseName=$databaseName${newline}"
    text+="declare sqlConnectionString=\"$sqlConnectionString\"${newline}"
    text+="declare resourceGroupName=$resourceGroupName${newline}"
    text+="declare appInsightsName=$appInsightsName${newline}"
    text+="declare subscriptionId=$subscriptionId${newline}"
    text+="declare apiKey=$(cat ~/$apiKeyTempFile)${newline}"
    text+="declare appId=$(cat ~/$appIdTempFile)${newline}"
    text+="declare instrumentationKey=$(cat ~/$instrumentationKeyTempFile)${newline}"
    text+="echo \"${green}${bold}Connection Info\"${newline}"
    text+="echo \"${magenta}${bold}DB Connection String: ${white}${plain}$sqlConnectionString\"${newline}"
    text+="echo \"${magenta}${bold}DB Host Name: ${white}${plain}$sqlHostName\"${newline}"
    text+="echo \"${magenta}${bold}DB User Name: ${white}${plain}$sqlUsername\"${newline}"
    text+="echo \"${magenta}${bold}DB Password: ${white}${plain}$sqlPassword\"${newline}"
    text+="echo \"${magenta}${bold}App Insights Instrumentation Key: ${white}${plain}$(cat ~/$instrumentationKeyTempFile)\"${newline}"
    text+="echo \"${magenta}${bold}App Insights App ID: ${white}${plain}$(cat ~/$appIdTempFile)\"${newline}"
    text+="echo \"${magenta}${bold}App Insights API Key: ${white}${plain}$(cat ~/$apiKeyTempFile)\"${newline}"
    text+="cd $srcWorkingDirectory${newline}"
    text=+"code .${newline}"
    text=+"cd $gitRepoWorkingDirectory${newline}"
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
    (
        echo "${white}Provisioning Azure Resource Group...${cyan}"
        set -x
        az group create \
            --name $resourceGroupName \
            --output none
    )
}

# Provision Azure SQL Database
provisionDatabase() {
    (
        echo "${white}Provisioning Azure SQL Database Server...${cyan}"
        set -x
        az sql server create \
            --name $sqlServerName \
            --admin-user $sqlUsername \
            --admin-password $sqlPassword \
            --output none
    )
    (
        echo "${white}Provisioning Azure SQL Database...${cyan}"
        set -x
        az sql db create \
            --name $databaseName \
            --server $sqlServerName \
            --output none
    )
    (
        echo "${white}Adding Azure IP addresses to Azure SQL Database firewall rules...${cyan}"
        set -x
        az sql server firewall-rule create \
            --name AllowAzureAccess \
            --start-ip-address 0.0.0.0 \
            --end-ip-address 0.0.0.0 \
            --server $sqlServerName \
            --output none
    )
}

provisionAppInsights() {
    (
        echo "${white}Provisioning Azure Monitor Application Insights...${cyan}"
        set -x
        az resource create \
            --resource-type microsoft.insights/components \
            --name $appInsightsName \
            --is-full-object \
            --properties '{"kind":"web","location":"southcentralus","properties":{"Application_Type":"web"}}' \
            --output none
    )

    # Create an API Key for App Insights
    # There is no Az CLI command for this, so we must use the REST API.
    echo "${white}Using ${cyan}${bold}Azure REST API ${white}${plain}to get App ID and API Key from Application Insights..."

    appInsightsDetails=$(az resource show --resource-type microsoft.insights/components --name $appInsightsName)
    token=$(az account get-access-token --output tsv --query accessToken)
    aiPath=$"/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/microsoft.insights/components/$appInsightsName"
    body=$"{\"name\":\"$appInsightsName-ApiKey\",\"linkedReadProperties\":[\"$aiPath/api\"]}"
    len=$(expr length $body)
    url="https://management.azure.com$aiPath/apikeys?api-version=2015-05-01"
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
writeVariablesScript
cleanupTempFiles

# We're done! Summarize.
summary="${newline}${green}${bold}Your environment is ready!${white}${plain}${newline}"
summary+="I set up some ${cyan}${bold}Azure${white}${plain} resources and downloaded the code you'll need.${newline}"
summary+="You can display this information again by running ${red}${bold}. ~/setup.sh${white}${plain} from any location.${magenta}"
~/dotnetsay/dotnetsay "$summary"

. ~/$variableScript