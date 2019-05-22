(
    echo "${newline}${headingStyle}Provisioning Azure App Service Web App and deploying code...${azCliCommandStyle}"
    cd $srcWorkingDirectory/$projectRootDirectory
    set -x
    az webapp up \
        --name $webAppName \
        --output none \
        &>/dev/null #swallow all the output
)
