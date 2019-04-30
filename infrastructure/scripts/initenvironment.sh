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
declare dotnetsdkversion=$(dotnet --version)

# Functions
determineResourceGroup(){
    # Figure out the name of the resource group to use
    declare resourceGroupCount=$(az group list | jq '. | length')
    declare existingResourceGroup=$(az group list | jq '.[0].name' --raw-output)
    declare resourceGroupName=""
    declare rgStatus=""

    # If there is more than one RG or there's only one but its name is not a GUID,
    # we're probably not in the Learn sandbox.
    if [[ ! ${existingResourceGroup//-/} =~ ^[[:xdigit:]]{32}$ ]] || [ $resourceGroupCount -gt 1 ]
    then
        echo "${warningStyle}WARNING!!!${defaultTextStyle}" \
            "It doesn't appear you are currently running in a Microsoft Learn sandbox." \
            "Using default resource group."
        resourceGroupName=$moduleName
    else
        resourceGroupName=$existingResourceGroup
    fi

    echo "Using Azure resource group ${azCliCommandStyle}$resourceGroupName${defaultTextStyle}."
}
setAzureCliDefaults() {
    echo "${defaultTextStyle}Setting default Azure CLI values...${azCliCommandStyle}"
    (
        set -x
        az configure --defaults \
            group=$resourceGroupName \
            location=SouthCentralUs
    )
}
resetAzureCliDefaults() {
    echo "${defaultTextStyle}Resetting default Azure CLI values...${azCliCommandStyle}"
    (
        set -x
        az configure --defaults \
            group= \
            location=
    )
}
configureDotNetCli() {
    echo "${newline}${defaultTextStyle}Configuring the .NET Core CLI..."

    # By default, the .NET Core CLI prints Welcome and Telemetry messages on
    # the first run. Suppress those messages by creating an appropriately
    # named file on disk.
    touch ~/.dotnet/$dotnetsdkversion.dotnetFirstUseSentinel

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
    echo "${newline}${defaultTextStyle}Downloading code...${headingStyle}"
    (
        set -x
        curl -s $gitPathToCloneScript | bash -s $gitDirectoriesToClone
    )
    echo "${newline}${defaultTextStyle}Building code...${dotnetCliCommandStyle}"
    (
        set -x 
        cd srcWorkingDirectory/$projectRootDirectory
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
        echo "${newline}${defaultTextStyle}Provisioning Azure SQL Database Server...${azCliCommandStyle}"
        set -x
        az sql server create \
            --name $sqlServerName \
            --admin-user $sqlUsername \
            --admin-password $sqlPassword \
            --output none
    )
    (
        echo "${newline}${defaultTextStyle}Provisioning Azure SQL Database...${azCliCommandStyle}"
        set -x
        az sql db create \
            --name $databaseName \
            --server $sqlServerName \
            --output none
    )
    (
        echo "${newline}${defaultTextStyle}Adding Azure IP addresses to Azure SQL Database firewall rules...${azCliCommandStyle}"
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
# Provision Azure Resource Group
provisionResourceGroup() {
    if [ $resourceGroupName -eq $moduleName ]
    then
        (
            echo "${newline}${defaultTextStyle}Provisioning Azure Resource Group...${azCliCommandStyle}"
            set -x
            az group create \
                --name $resourceGroupName \
                --output none
        )
    fi
}
addVariablesToStartup(){
    if ! [ $(grep $moduleName .bashrc) ]
    then
        echo "# $moduleName" >> .bashrc
        echo "# Next line added at $(date)" >> .bashrc
        echo ". ~/$variableScript" >> .bashrc
    fi 
}
greeting(){
    # Set location
    cd ~

    # Display installed .NET Core SDK version
    echo "${headingStyle}Using .NET Core SDK version $dotnetsdkversion${defaultTextStyle}"

    # Install .NET Core global tool to display connection info
    dotnet tool install dotnetsay --global

    # Greetings!
    greeting="${newline}${defaultTextStyle}Hi there!${newline}"
    greeting+="I'm going to provision some ${azCliCommandStyle}Azure${defaultTextStyle} resources${newline}"
    greeting+="and get the code you'll need for this module.${dotnetCliCommandStyle}"

    dotnetsay "$greeting"
}
summarize(){
    summary="${newline}${successStyle}Your environment is ready!${defaultTextStyle}${newline}"
    summary+="I set up some ${azCliCommandStyle}Azure${defaultTextStyle} resources and downloaded the code you'll need.${newline}"
    summary+="You can resume this session and display this message again by re-running the script.${headingStyle}"
    dotnetsay "$summary"

    . ~/$variableScript
}


# Check to make sure we're in Azure Cloud Shell
if [ "${AZURE_HTTP_USER_AGENT:0:11}" != "cloud-shell" ]
then
    echo "${warningStyle}WARNING!!!${defaultTextStyle}" \
        "It appears that you're not running this script in an instance of Azure Cloud Shell." \
        "This script was designed for the environment in Azure Cloud Shell, and we can make no promises that it'll function as intended anywhere else." \
        "Please only proceed if you know what you're doing.${newline}${newline}" \
        "${warningStyle}Do you know what you're doing?${defaultTextStyle}"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) echo "${warningStyle}Please let us know that you saw this message using the feedback links provided.${plain}${white}"; return 0;;
        esac
    done
fi

configureDotNetCli
greeting
determineResourceGroup
downloadAndBuild
setAzureCliDefaults