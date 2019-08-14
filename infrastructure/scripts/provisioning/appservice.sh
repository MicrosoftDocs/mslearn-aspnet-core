(
    echo "${newline}${headingStyle}Provisioning $webAppLabel Web App...${azCliCommandStyle}"
    cd $srcWorkingDirectory/$projectRootDirectory
    set -x
    az webapp create \
        --name $webAppName \
        --plan $webPlanName \
        --output none
)
