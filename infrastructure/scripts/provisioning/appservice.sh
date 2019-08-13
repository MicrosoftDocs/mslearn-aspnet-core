(
<<<<<<< HEAD
    echo "${newline}${headingStyle}Provisioning Azure App Service Web App and deploying code...${azCliCommandStyle}"
    cd $srcWorkingDirectory/$projectRootDirectory
    set -x
    az webapp up \
        --name $webAppName
=======
    echo "${newline}${headingStyle}Provisioning $webAppLabel Web App...${azCliCommandStyle}"
    cd $srcWorkingDirectory/$projectRootDirectory
    set -x
    az webapp create \
        --name $webAppName \
        --plan $webPlanName \
        --output none
>>>>>>> origin/create-razor-pages-aspnet-core
)
