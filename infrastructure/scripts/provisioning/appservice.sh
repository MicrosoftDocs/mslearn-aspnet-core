(
    echo "${newline}${headingStyle}Provisioning $webAppLabel Web App...${azCliCommandStyle}"
    cd $srcWorkingDirectory/$projectRootDirectory
    set -x
    az webapp create \
        --name $webAppName \
        --plan $webPlanName \
        --output none
)
(
    echo "${newline}${headingStyle}Configuring $webAppLabel Web App...${azCliCommandStyle}"
    cd $srcWorkingDirectory/$projectRootDirectory
    set -x
    az webapp config appsettings set \
        --name $webAppName \
        --settings SCM_DO_BUILD_DURING_DEPLOYMENT=True \
        --output none
)
