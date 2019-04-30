# This script expects the following environment variables:
# moduleName
# scriptPath
# projectRootDirectory

# Declarations
declare scriptPath=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts
declare instanceId=$(($RANDOM * $RANDOM))
declare gitDirectoriesToClone="modules/$moduleName/setup/ modules/$moduleName/src/"
declare gitPathToCloneScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/sparsecheckout.sh
declare srcWorkingDirectory=~/contoso-pets/src
declare setupWorkingDirectory=~/contoso-pets/setup
declare subscriptionId=$(az account show --query id --output tsv)
declare dotnetSdkVersion=$(dotnet --version)
declare resourceGroupName=""

# Functions
setAzureCliDefaults() {
    echo "${headingStyle}Setting default Azure CLI values...${azCliCommandStyle}"
    (
        set -x
        az configure --defaults \
            group=$resourceGroupName \
            location=SouthCentralUs
    )
}
resetAzureCliDefaults() {
    echo "${headingStyle}Resetting default Azure CLI values...${azCliCommandStyle}"
    (
        set -x
        az configure --defaults \
            group= \
            location=
    )
}
configureDotNetCli() {
    echo "${newline}${headingStyle}Configuring the .NET Core CLI...${defaultTextStyle}"

    # By default, the .NET Core CLI prints Welcome and Telemetry messages on
    # the first run. Suppress those messages by creating an appropriately
    # named file on disk.
    touch ~/.dotnet/$dotnetSdkVersion.dotnetFirstUseSentinel

    # Disable the sending of telemetry to the mothership.
    export DOTNET_CLI_TELEMETRY_OPTOUT=true

    # Add ~/.dotnet/tools to the path so .NET Core Global Tool shims can be found
    if ! [ $(echo $PATH | grep ~/.dotnet/tools) ]; then export PATH=$PATH:~/.dotnet/tools; fi
}
downloadAndBuild() {
    # Set location
    cd ~

    # Set global Git config variables
    git config --global user.name "Microsoft Learn Student"
    git config --global user.email learn@contoso.com
    
    # Download the sample project, restore NuGet packages, and build
    echo "${newline}${headingStyle}Downloading code...${defaultTextStyle}"
    (
        set -x
        curl -s $gitPathToCloneScript | bash -s $gitDirectoriesToClone
    )
    echo "${newline}${headingStyle}Building code...${defaultTextStyle}"
    (
        cd $srcWorkingDirectory/$projectRootDirectory
        echo "${dotnetCliCommandStyle}"
        set -x
        dotnet build --verbosity quiet
    )
    echo "${defaultTextStyle}"
}
# Provision Azure SQL Database
provisionDatabase() {
    #This function expects:
    # sqlServerName
    # sqlUsername
    # sqlPassword
    # databaseName
    (
        echo "${newline}${headingStyle}Provisioning Azure SQL Database Server...${azCliCommandStyle}"
        set -x
        az sql server create \
            --name $sqlServerName \
            --admin-user $sqlUsername \
            --admin-password $sqlPassword \
            --output none
    )
    (
        echo "${newline}${headingStyle}Provisioning Azure SQL Database...${azCliCommandStyle}"
        set -x
        az sql db create \
            --name $databaseName \
            --server $sqlServerName \
            --output none
    )
    (
        echo "${newline}${headingStyle}Adding Azure IP addresses to Azure SQL Database firewall rules...${azCliCommandStyle}"
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
# Provision App Insights
provisionAppInsights() {
    (
        echo "${newline}${headingStyle}Provisioning Azure Monitor Application Insights...${azCliCommandStyle}"
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

    echo "${newline}${headingStyle}Using Azure REST API to set an API Key in Application Insights. The command looks like this (abridged for brevity):"
    echo "${defaultTextStyle}curl -X POST \\${newline}" \
            "-H \"Authorization: Bearer <token>\" \\${newline}" \
            "-H \"Content-Type: application/json\" \\${newline}" \
            "-H \"Content-Length: <content length>\" \\${newline}" \
            "-s \\${newline}" \
            "<azure management endpoint url> \\${newline}" \
            "-d \"{\\\"name\\\":\\\"<api key name>\\\",\\\"linkedReadProperties\\\":[\\\"<app insights resource uri>/api\\\"]}\""

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
# Provision Azure Resource Group
provisionResourceGroup() {
    if [ "$resourceGroupName" = "$moduleName" ]; then
        (
            echo "${newline}${headingStyle}Provisioning Azure Resource Group...${azCliCommandStyle}"
            set -x
            az group create \
                --name $resourceGroupName \
                --output none
        )
    fi
}
addVariablesToStartup() {
    if ! [[ $(grep $moduleName ~/.bashrc) ]]; then
        echo "# Next line added at $(date) by $moduleName" >> ~/.bashrc
        echo ". ~/$variableScript" >> ~/.bashrc
    fi 
}
displayGreeting() {
    # Set location
    cd ~

    # Display installed .NET Core SDK version
    echo "${headingStyle}Using .NET Core SDK version $dotnetSdkVersion${defaultTextStyle}"

    # Install .NET Core global tool to display connection info
    dotnet tool install dotnetsay --global

    # Greetings!
    greeting="${newline}${defaultTextStyle}Hi there!${newline}"
    greeting+="I'm going to provision some ${azCliCommandStyle}Azure${defaultTextStyle} resources${newline}"
    greeting+="and get the code you'll need for this module.${dotnetCliCommandStyle}"

    dotnetsay "$greeting"
}
summarize() {
    summary="${newline}${successStyle}Your environment is ready!${defaultTextStyle}${newline}"
    summary+="I set up some ${azCliCommandStyle}Azure${defaultTextStyle} resources and downloaded the code you'll need.${newline}"
    summary+="You can resume this session and display this message again by re-running the script.${dotnetCliCommandStyle}"
    dotnetsay "$summary"

    . ~/$variableScript
}
determineResourceGroup() {
    # Figure out the name of the resource group to use
    declare resourceGroupCount=$(az group list | jq '. | length')
    declare existingResourceGroup=$(az group list | jq '.[0].name' --raw-output)

    # If there is more than one RG or there's only one but its name is not a GUID,
    # we're probably not in the Learn sandbox.
    if [[ ! ${existingResourceGroup//-/} =~ ^[[:xdigit:]]{32}$ ]] || [ $resourceGroupCount -gt 1 ]
    then
        echo "${warningStyle}WARNING!!!" \
            "It doesn't appear you are currently running in a Microsoft Learn sandbox." \
            "Using default resource group.${defaultTextStyle}"
        resourceGroupName=$moduleName
    else
        resourceGroupName=$existingResourceGroup
    fi

    echo "Using Azure resource group ${azCliCommandStyle}$resourceGroupName${defaultTextStyle}."
}
checkForCloudShell() {
    # Check to make sure we're in Azure Cloud Shell
    if [ "${AZURE_HTTP_USER_AGENT:0:11}" != "cloud-shell" ]
    then
        echo "${warningStyle}WARNING!!!" \
            "It appears that you're not running this script in an instance of Azure Cloud Shell." \
            "This script was designed for the environment in Azure Cloud Shell, and we can make no promises that it'll function as intended anywhere else." \
            "Please only proceed if you know what you're doing.${newline}${newline}" \
            "Do you know what you're doing?${defaultTextStyle}"
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) break;;
                No ) echo "${warningStyle}Please let us know that you saw this message using the feedback links provided.${defaultTextStyle}"; return 0;;
            esac
        done
    fi
}


# Load the theme
declare themeScript=$scriptPath/theme.sh
. <(wget -q -O - $themeScript)

# Execute functions
checkForCloudShell
determineResourceGroup
configureDotNetCli
displayGreeting
downloadAndBuild
setAzureCliDefaults

# Additional setup in setup.sh occurs next.