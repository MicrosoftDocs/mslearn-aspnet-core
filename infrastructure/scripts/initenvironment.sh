# This script expects the following environment variables:
# moduleName
# scriptPath
# projectRootDirectory



# Common Declarations
declare scriptPath=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts
declare provisioningPath=$scriptPath/provisioning
declare toolsPath=$scriptPath/tools
declare dotnetScriptsPath=$scriptPath/dotnet
declare binariesPath=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/binaries
declare instanceId=$(($RANDOM * $RANDOM))
declare gitDirectoriesToClone="modules/$moduleName/setup/ modules/$moduleName/src/"
declare gitPathToCloneScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/sparsecheckout.sh
if ! [ $rootLocation ]
then
    declare rootLocation=~
fi
declare srcWorkingDirectory=$rootLocation/aspnet-learn/src
declare setupWorkingDirectory=$rootLocation/aspnet-learn/setup
declare subscriptionId=$(az account show --query id --output tsv)
declare resourceGroupName=""
if ! [ $defaultRegion ]
then
    declare defaultRegion="centralus"
fi


# AppService Declarations
declare appServicePlan=appservice$instanceId
declare webAppName=webapp$instanceId
declare webPlanName=plan$instanceId
declare webAppUrl="https://$webAppName.azurewebsites.net"

# Key Vault Declarations
declare keyVaultName=keyvault$instanceId

# AppInsights Declarations
declare appInsightsName=appinsights$instanceId
declare apiKeyTempFile=~/.apiKey.temp
declare appIdTempFile=~/.appId.temp
declare instrumentationKeyTempFile=~/.instrumentationKey.temp

# Azure SQL Database Declarations
declare sqlServerName=azsql$instanceId
declare sqlHostName=$sqlServerName.database.windows.net
declare sqlUsername=SqlUser
declare sqlPassword=Pass.$RANDOM.word
declare databaseName=ContosoPetsAuth
declare sqlConnectionString="Data Source=$sqlHostName;Initial Catalog=$databaseName;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False"

# Azure Database for PostgreSQL Declarations
declare postgreSqlSku=B_Gen5_1
declare postgreSqlServerName=postgresql$instanceId
declare postgreSqlHostName=$postgreSqlServerName.postgres.database.azure.com
declare postgreSqlUsername=pgsqluser
declare postgreSqlPassword=Pass.$RANDOM.word
declare postgreSqlDatabaseName=contosopetsauth
declare postgreSqlConnectionString="Server=$postgreSqlHostName;Database=$postgreSqlDatabaseName;Port=5432;Ssl Mode=Require;"

# Functions
setAzureCliDefaults() {
    echo "${headingStyle}Setting default Azure CLI values...${azCliCommandStyle}"
    (
        set -x
        az configure --defaults \
            group=$resourceGroupName \
            location=$defaultRegion
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
    echo "${newline}${headingStyle}Configuring the .NET CLI...${defaultTextStyle}"
    declare installedDotNet=$(dotnet --version)

    if [ "$dotnetSdkVersion" != "$installedDotNet" ];
    then
        # Install .NET SDK
        wget -q -O - https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --version $dotnetSdkVersion
    fi

    setPathEnvironmentVariableForDotNet
    setDotnetRootEnvironmentVariable

    # By default, the .NET CLI prints Welcome and Telemetry messages on
    # the first run. Suppress those messages by creating an appropriately
    # named file on disk.
    touch ~/.dotnet/$dotnetSdkVersion.dotnetFirstUseSentinel

    # Suppress priming the NuGet package cache with assemblies and 
    # XML docs we won't need.
    export NUGET_XMLDOC_MODE=skip
    echo "export NUGET_XMLDOC_MODE=skip" >> ~/.bashrc
    
    # Disable the sending of telemetry to the mothership.
    export DOTNET_CLI_TELEMETRY_OPTOUT=true
    echo "export DOTNET_CLI_TELEMETRY_OPTOUT=true" >> ~/.bashrc

    # Disable add'l welcome messages and logo stuff
    export DOTNET_NOLOGO=true
    echo "export DOTNET_NOLOGO=true" >> ~/.bashrc

    # Add tab completion for .NET CLI
    tabSlug="#dotnet-tab-completion"
    tabScript=$dotnetScriptsPath/tabcomplete.sh
    if ! [[ $(grep $tabSlug ~/.bashrc) ]]; then
        echo $tabSlug >> ~/.bashrc
        wget -q -O - $tabScript >> ~/.bashrc
        . <(wget -q -O - $tabScript)
    fi
    
    # Generate developer certificate so ASP.NET Core projects run without complaint
    dotnet dev-certs https --quiet
}
setPathEnvironmentVariableForDotNet() {
    # Add a note to .bashrc in case someone is running this in their own Cloud Shell
    echo "# The following was added by Microsoft Learn $moduleName" >> ~/.bashrc

    # Add .NET SDK and .NET Global Tools default installation directory to PATH
    if ! [ $(echo $PATH | grep .dotnet) ]; then 
        export PATH=~/.dotnet:~/.dotnet/tools:$PATH; 
        echo "# Add custom .NET SDK to PATH" >> ~/.bashrc
        echo "export PATH=~/.dotnet:~/.dotnet/tools:\$PATH;" >> ~/.bashrc
    fi
}
setDotnetRootEnvironmentVariable() {
    # Add .NET Global Tools directory variable
    if ! [ $(echo $DOTNET_ROOT | grep .dotnet) ]; then 
        export DOTNET_ROOT=~/.dotnet
        echo "# Add DOTNET_ROOT variable" >> ~/.bashrc
        echo "export DOTNET_ROOT=~/.dotnet" >> ~/.bashrc
    fi
}
downloadStarterApp() {
    if ! [ "$suppressShallowClone" ]; then
        # Set location
        cd $rootLocation

        # Set global Git config variables
        git config --global user.name "Microsoft Learn Student"
        git config --global user.email learn@contoso.com
        
        # Download the sample project, restore NuGet packages, and build
        echo "${newline}${headingStyle}Downloading code...${defaultTextStyle}"
        (
            set -x
            wget -q -O - $gitPathToCloneScript | bash -s $gitDirectoriesToClone
        )
        echo "${defaultTextStyle}"
    fi
}
# Provision Azure SQL Database
provisionAzSqlDatabase() {
    declare provisionScript=$provisioningPath/azuresql.sh
    . <(wget -q -O - $provisionScript)
}
# Provision Azure Database for PostgreSQL
provisionAzPostgreSqlDatabase() {
    declare provisionScript=$provisioningPath/azurepostgresql.sh
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
# Provision Azure Key Vault
provisionKeyVault() {
    declare provisionScript=$provisioningPath/keyvault.sh
    . <(wget -q -O - $provisionScript)
}
# Provision Azure App Service Plan
provisionAppServicePlan() {
    declare provisionScript=$provisioningPath/appserviceplan.sh
    . <(wget -q -O - $provisionScript)
}
# Provision Azure Resource Group
# Should only ever run if we're running in the Cloud Shell without the Learn environment
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
    if ! [[ $(grep $variableScript ~/.bashrc) ]]; then
        echo "${newline}# Next line added at $(date) by Microsoft Learn $moduleName" >> ~/.bashrc
        echo ". ~/$variableScript" >> ~/.bashrc
    fi 
}
displayGreeting() {
    # Set location
    cd ~

    # Display installed .NET SDK version
    if ! [ "$suppressConfigureDotNet" ]; then
        echo "${defaultTextStyle}Using .NET SDK version ${headingStyle}$dotnetSdkVersion${defaultTextStyle}"
    fi
    
    # Install .NET global tool to display connection info
    dotnet tool install dotnetsay --global --version 2.1.7 --verbosity quiet

    # Greetings!
    if [ "$dotnetBotGreeting" ]; then
        greeting="${newline}${defaultTextStyle}$dotnetBotGreeting${dotnetSayStyle}"
    else
        greeting="${newline}${defaultTextStyle}Hi there!${newline}"
        greeting+="I'm going to provision some ${azCliCommandStyle}Azure${defaultTextStyle} resources${newline}"
        greeting+="and get the code you'll need for this module.${dotnetSayStyle}"
    fi

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
            "It appears you aren't currently running in a Microsoft Learn sandbox." \
            "Any Azure resources provisioned by this script will result in charges" \
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
if ! [ "$suppressAzureResources" ]; then
    determineResourceGroup
fi
if ! [ "$suppressConfigureDotNet" ]; then
    configureDotNetCli
else
    setPathEnvironmentVariableForDotNet
fi
displayGreeting

# Additional setup in setup.sh occurs next.
