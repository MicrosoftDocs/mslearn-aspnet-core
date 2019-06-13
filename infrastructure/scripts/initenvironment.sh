# This script expects the following environment variables:
# moduleName
# scriptPath
# projectRootDirectory

# Common Declarations
declare scriptPath=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts
declare provisioningPath=$scriptPath/provisioning
declare defaultLocation=southcentralus
declare instanceId=$(($RANDOM * $RANDOM))
declare gitDirectoriesToClone="modules/$moduleName/setup/ modules/$moduleName/src/"
declare gitPathToCloneScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/sparsecheckout.sh
declare srcWorkingDirectory=~/contoso-pets/src
declare setupWorkingDirectory=~/contoso-pets/setup
declare subscriptionId=$(az account show --query id --output tsv)
declare dotnetSdkVersion=$(dotnet --version)
declare resourceGroupName=""

# AppService Declarations
declare appServicePlan=appservice$instanceId
declare webAppName=webapp$instanceId

# AppInsights Declarations
declare appInsightsName=appinsights$instanceId
declare apiKeyTempFile=~/.apiKey.temp
declare appIdTempFile=~/.appId.temp
declare instrumentationKeyTempFile=~/.instrumentationKey.temp

# SQL Database Declarations
declare sqlServerName=azsql$instanceId
declare sqlHostName=$sqlServerName.database.windows.net
declare sqlUsername=SqlUser
declare sqlPassword=Pass.$RANDOM.word
declare databaseName=ContosoPets
declare sqlConnectionString="Data Source=$sqlHostName;Initial Catalog=$databaseName;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False"

# Functions
setAzureCliDefaults() {
    echo "${headingStyle}Setting default Azure CLI values...${azCliCommandStyle}"
    (
        set -x
        az configure --defaults \
            group=$resourceGroupName \
            location=$defaultLocation
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
        wget -q -O - $gitPathToCloneScript | bash -s $gitDirectoriesToClone
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
provisionAzSqlDatabase() {
    declare provisionScript=$provisioningPath/azuresql.sh
    . <(wget -q -O - $provisionScript)
}
# Provision App Insights
provisionAppInsights() {
    declare provisionScript=$provisioningPath/appinsights.sh
    . <(wget -q -O - $provisionScript)
}
# Provision Azure App Service
provisionAppService() {
    declare provisionScript=$provisioningPath/appservice.sh
    . <(wget -q -O - $provisionScript)
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
    greeting+="and get the code you'll need for this module.${dotnetSayStyle}"

    dotnetsay "$greeting"
}
summarize() {
    summary="${newline}${successStyle}Your environment is ready!${defaultTextStyle}${newline}"
    summary+="I set up some ${azCliCommandStyle}Azure${defaultTextStyle} resources and downloaded the code you'll need.${newline}"
    summary+="You can resume this session and display this message again by re-running the script.${dotnetSayStyle}"
    dotnetsay "$summary"
}
determineResourceGroup() {
    # Figure out the name of the resource group to use
    declare existingResourceGroup=$(az group list | jq '.[] | select(.tags."x-created-by"=="freelearning").name' --raw-output)

    # If there is more than one RG or there's only one but its name is not a GUID,
    # we're probably not in the Learn sandbox.
    if ! [ $existingResourceGroup ]
    then
        echo "${warningStyle}WARNING!!!" \
            "It appears you aren't currently running in a Microsoft Learn sandbox. " \
            "Any Azure resources provisioned by this script will result in charges " \
            "to your Azure subscription.${defaultTextStyle}"
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
            "It appears you aren't running this script in an instance of Azure Cloud Shell." \
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
cleanupTempFiles() {
    # App Insights
    rm $apiKeyTempFile
    rm $appIdTempFile
    rm $instrumentationKeyTempFile
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