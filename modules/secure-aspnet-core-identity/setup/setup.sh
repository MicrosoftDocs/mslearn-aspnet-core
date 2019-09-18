#!/bin/bash

# Hi!
# If you're reading this, you're probably interested in what's 
# going on within this script. We've provided what we hope are useful
# comments inline, as well as color-coded relevant shell output.
# We hope it's useful for you, but if you have any questions or suggestions
# please open an issue on https:/github.com/MicrosoftDocs/mslearn-aspnet-core.
#

## Start

# Input parameters
declare -x dbType=$1

# Module name
declare moduleName="secure-aspnet-core-identity"

# dotnet SDK version
declare -x dotnetSdkVersion="2.2.401"

# Any other declarations we need
declare -x gitBranch="live"
declare initScript=https://raw.githubusercontent.com/MicrosoftDocs/mslearn-aspnet-core/$gitBranch/infrastructure/scripts/initenvironment.sh
declare -x projectRootDirectory="ContosoPets.Ui"

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
    text+="declare resourceGroupName=$resourceGroupName${newline}"
    text+="declare subscriptionId=$subscriptionId${newline}"
    text+="declare webAppName=$webAppName${newline}"
    text+="declare webPlanName=$webPlanName${newline}"
    text+="declare webAppUrl=$webAppUrl${newline}"
    text+="export ASPNETCORE_HOSTINGSTARTUP__KEYVAULT__CONFIGURATIONVAULT=https://$keyVaultName.vault.azure.net${newline}"
    
    if [ "$dbType" = "pg" ];
    then
        text+="declare postgreSqlServerName=$postgreSqlServerName${newline}"
        text+="declare postgreSqlHostName=$postgreSqlHostName${newline}"
        text+="declare postgreSqlUsername=$postgreSqlUsername@$postgreSqlServerName${newline}"
        text+="export PGPASSWORD=$postgreSqlPassword${newline}"
        text+="declare dbConnectionString=\"$postgreSqlConnectionString\"${newline}"
        text+="declare postgreSqlDatabaseName=$postgreSqlDatabaseName${newline}"
        text+="alias db=\"psql --host=$postgreSqlHostName --port=5432 --username=$postgreSqlUsername@$postgreSqlServerName --dbname=$postgreSqlDatabaseName\"${newline}"
    else
        text+="declare sqlServerName=$sqlServerName${newline}"
        text+="declare sqlHostName=$sqlHostName${newline}"
        text+="declare sqlUsername=$sqlUsername@$sqlServerName${newline}"
        text+="declare sqlPassword=$sqlPassword${newline}"
        text+="declare databaseName=$databaseName${newline}"
        text+="declare dbConnectionString=\"$sqlConnectionString\"${newline}"
        text+="alias db=\"sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName\"${newline}"
    fi

    text+="echo \"${headingStyle}The following variables are used in this module:\"${newline}"
    text+="echo \"${headingStyle}webAppUrl: ${defaultTextStyle}$webAppUrl\"${newline}"
    if [ "$dbType" = "pg" ];
    then
        text+="echo \"${headingStyle}dbConnectionString: ${defaultTextStyle}$postgreSqlConnectionString\"${newline}"
        text+="echo \"${headingStyle}postgreSqlUsername: ${defaultTextStyle}$postgreSqlUsername\"${newline}"
        text+="echo \"${headingStyle}PGPASSWORD: ${defaultTextStyle}$postgreSqlPassword\"${newline}"
        text+="echo ${newline}"
        text+="echo \"${defaultTextStyle}db ${headingStyle}is an alias for${defaultTextStyle} psql --host=$postgreSqlHostName --port=5432 --username=$postgreSqlUsername@$postgreSqlServerName --dbname=$postgreSqlDatabaseName\"${newline}"
    else
        text+="echo \"${headingStyle}dbConnectionString: ${defaultTextStyle}$sqlConnectionString\"${newline}"
        text+="echo \"${headingStyle}sqlUsername: ${defaultTextStyle}$sqlUsername\"${newline}"
        text+="echo \"${headingStyle}sqlPassword: ${defaultTextStyle}$sqlPassword\"${newline}"
        text+="echo ${newline}"
        text+="echo \"${defaultTextStyle}db ${headingStyle}is an alias for${defaultTextStyle} sqlcmd -U $sqlUsername -P $sqlPassword -S $sqlHostName -d $databaseName\"${newline}"
    fi
    text+="if ! [ \$(echo \$PATH | grep ~/.dotnet/tools) ]; then export PATH=\$PATH:~/.dotnet/tools; fi${newline}"
    text+="echo ${newline}"
    text+="cd $srcWorkingDirectory/$projectRootDirectory${newline}"
    text+="code .${newline}"
    echo "$text" > ~/$variableScript
    chmod +x ~/$variableScript
}
writeAzWebappConfig(){
    mkdir $srcWorkingDirectory/$projectRootDirectory/.azure && pushd $_
    echo "[defaults]" > config
    echo "group = $resourceGroupName" >> config
    echo "sku = FREE" >> config
    echo "appserviceplan = $webPlanName" >> config
    echo "location = $defaultLocation" >> config
    echo "web = $webAppName" >> config
    popd
}

# Grab and run initenvironment.sh
. <(wget -q -O - $initScript)

# Download and build
downloadAndBuild

# Provision stuff here
setAzureCliDefaults
provisionResourceGroup
provisionAppServicePlan

(
    # API web app
    declare -x webAppName=apiapp$instanceId
    declare -x projectRootDirectory="ContosoPets.Api"
    declare -x webAppLabel="ContosoPets.Api API"
    provisionAppService

    # Deploy the app because it's a dependency.
    cd $srcWorkingDirectory/$projectRootDirectory
    az webapp up --name $webAppName --plan $webPlanName &> ../apiapp-deploy.log
) &
(   
    # UI web app
    declare -x webAppName=webapp$instanceId
    declare -x projectRootDirectory="ContosoPets.Ui"
    declare -x webAppLabel="ContosoPets.Ui Web App"
    provisionAppService 

    ## Key Vault for UI web app
    provisionKeyVault
    declare -x userTemp
    declare -x passwordTemp
    if [ "$dbType" = "pg" ];
    then
        userTemp=$postgreSqlUsername@$postgreSqlServerName && passwordTemp=$postgreSqlPassword
    else
        userTemp=$sqlUsername && passwordTemp=$sqlPassword
    fi
    
    (
        echo "${newline}${headingStyle}Adding database username to Azure Key Vault...${azCliCommandStyle}"
        set -x
        az keyvault secret set \
            --vault-name $keyVaultName \
            --name "DbUsername" \
            --value "$userTemp" \
            --output none &
    )
    (
        sleep 3 # Adding a small wait to resolve a race condition
        echo "${newline}${headingStyle}Adding database password to Azure Key Vault...${azCliCommandStyle}"
        set -x
        az keyvault secret set \
            --vault-name $keyVaultName \
            --name "DbPassword" \
            --value "$passwordTemp" \
            --output none 
    )
    (
        echo "${newline}${headingStyle}Setting Web App environment variable with location of Key Vault...${azCliCommandStyle}"
        set -x
        az webapp config appsettings set \
            --name $webAppName \
            --settings ASPNETCORE_HOSTINGSTARTUP__KEYVAULT__CONFIGURATIONVAULT=https://$keyVaultName.vault.azure.net \
            --output none
    )
) &

if [ "$dbType" = "pg" ];
then
    provisionAzPostgreSqlDatabase & 
else
    provisionAzSqlDatabase &
fi

wait &>/dev/null

# Point to the Web to the API
cd $srcWorkingDirectory/$projectRootDirectory
sed -i "s|<web-app-name>|apiapp$instanceId|g" appsettings.json

# Setup az webapp up
writeAzWebappConfig

# Clean up
writeVariablesScript
addVariablesToStartup

# We're done! Summarize.
summarize

# Run the variables script to make sure everything is as expected
. ~/$variableScript
