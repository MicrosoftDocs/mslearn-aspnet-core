(
    if [ ! $webAppLabel ]
    then
        declare webAppLabel="Azure App Service"
    fi
    echo "${newline}${headingStyle}Provisioning $webAppLabel Web App and deploying code...${azCliCommandStyle}"
    cd $srcWorkingDirectory/$projectRootDirectory
    set -x
    az webapp up \
        --name $webAppName \
        --plan $webPlanName
        --output none \
        # &>/dev/null #swallow all the output
)
