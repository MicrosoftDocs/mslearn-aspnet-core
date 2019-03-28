#!/bin/bash

# Generate a random number for unique resource names
declare instanceId=$(($RANDOM * $RANDOM))

# Variables
declare gitUrl=https://github.com/MicrosoftDocs/mslearn-aspnet-core
declare gitBranch=persist-data-ef-core
declare srcWorkingDirectory=~/mslearn-aspnet-core/src
declare gitRepoWorkingDirectory=$srcWorkingDirectory/ContosoPets.Api

declare sqlServerName=sql$instanceId
declare sqlHostName=$sqlServerName.database.windows.net
declare sqlUsername=SqlUser
declare sqlPassword=Pass.$RANDOM.word
declare databaseName=ContosoPets
declare sqlConnectionString="Data Source=$sqlServerName.database.windows.net;Initial Catalog=$databaseName;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False"
declare resourceGroupName=EfCoreModule

declare appInsightsName=ai$instanceId
declare subscriptionId=$(az account show --query id --output tsv)

declare apiKeyTempFile='apiKey.temp'
declare appIdTempFile='appId.temp'
declare instrumentationKeyTempFile='instrumentationKey.temp'
declare connectFile='connect.txt'
declare variableScript='remember.sh'

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
    ~/dotnetsay/dotnetsay $'\n\033[1;37mHi there!\n\033[0;37mI\'m going to setup some \033[1;34mAzure\033[0;37m resources\nand get the code you\'ll need for this module.\033[1;35m'
    echo $'\033[0;37m'

    echo "${green}Deployment tasks run asynchronously from here on.${white}"
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
        set -x; 
        cd $gitRepoWorkingDirectory
        dotnet build --verbosity quiet
    ) 
}

writeResultsFile() {
    connectInfo=$'\n'
    connectInfo+=$'\033[1;32m\033[4mConnection Info\033[0;37m (view again by running: \033[1;37m. ~/remember.sh \033[0;37m)'
    connectInfo+=$'\n'

    # db connection
    connectInfo+=$'\033[1;35mDB Connection String:\033[0;37m '
    connectInfo+=$sqlConnectionString
    connectInfo+=$'\n' 
    # username 
    connectInfo+=$'\033[1;35mDB Hostname: \033[0;37m'
    connectInfo+=$sqlHostName
    connectInfo+=$'\n'
    # username 
    connectInfo+=$'\033[1;35mDB Username: \033[0;37m'
    connectInfo+=$sqlUsername@$sqlServerName 
    connectInfo+=$'\n'
    # password
    connectInfo+=$'\033[1;35mDB Password: \033[0;37m'
    connectInfo+=$sqlPassword
    connectInfo+=$'\n'

    # App Insights Instrumentation Key
    connectInfo+=$'\033[1;35mApplication Insights Instrumentation Key: \033[0;37m'
    connectInfo+=$(cat ~/$instrumentationKeyTempFile)
    connectInfo+=$'\n'

    # App Insights App ID
    connectInfo+=$'\033[1;35mApplicationInsights App ID: \033[0;37m'
    connectInfo+=$(cat ~/$appIdTempFile)
    connectInfo+=$'\n'

    # App Insights API Key
    connectInfo+=$'\033[1;35mApplication Insights API Key: \033[0;37m'
    connectInfo+=$(cat ~/$apiKeyTempFile)
    connectInfo+=$'\n'

    # Set to purple for drawing .NET Bot
    #connectInfo+=$'\033[1;35m'

    echo "$connectInfo" > ~/$connectFile
}

# Write variables script
writeRememberScript() {
    text="#!/bin/bash"
    text+=$'\n'
    text+="declare gitUrl=$gitUrl"
    text+=$'\n'
    text+="declare gitBranch=$gitBranch"
    text+=$'\n'
    text+="declare srcWorkingDirectory=$srcWorkingDirectory"
    text+=$'\n'
    text+="declare gitRepoWorkingDirectory=$gitRepoWorkingDirectory"
    text+=$'\n'
    text+="declare sqlServerName=$sqlServerName"
    text+=$'\n'
    text+="declare sqlHostName=$sqlHostName"
    text+=$'\n'
    text+="declare sqlUsername=$sqlUsername"
    text+=$'\n'
    text+="declare sqlPassword=$sqlPassword"
    text+=$'\n'
    text+="declare databaseName=$databaseName"
    text+=$'\n'
    text+="declare sqlConnectionString=\"$sqlConnectionString\""
    text+=$'\n'
    text+="declare resourceGroupName=$resourceGroupName"
    text+=$'\n'
    text+="declare appInsightsName=$appInsightsName"
    text+=$'\n'
    text+="declare subscriptionId=$subscriptionId"
    text+=$'\n'
    text+="declare apiKey=$(cat ~/$apiKeyTempFile)"
    text+=$'\n'
    text+="declare appId=$(cat ~/$appIdTempFile)"
    text+=$'\n'
    text+="declare instrumentationKey=$(cat ~/$instrumentationKeyTempFile)"
    text+=$'\n'
    text+="cat ~/$connectFile"

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
    echo "${white}Provisioning Azure Resource Group...${cyan}"

    (
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
downloadAndBuild &
setAzureCliDefaults
provisionResourceGroup
provisionDatabase &
provisionAppInsights &
wait &>/dev/null
editSettings
resetAzureCliDefaults
cd $srcWorkingDirectory
writeResultsFile
code .
cd $gitRepoWorkingDirectory
writeRememberScript
cleanupTempFiles

# We're done! Summarize.
echo $'Done!\n\n'
~/dotnetsay/dotnetsay $'\n\033[1;37mYour environment is ready!\n\033[0;37mI set up some \033[1;34mAzure\033[0;37m resources and downloaded the code you\'ll need.\n\033[1;35mYou can find your connection information below.\033[1;35m'
. ~/$variableScript