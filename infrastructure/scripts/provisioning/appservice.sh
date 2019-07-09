(
    if ![ $webAppLabel ]
        $webAppLabel = "Azure App Service"
    fi
    echo "${newline}${headingStyle}Provisioning $webAppLabel Web App and deploying code...${azCliCommandStyle}"
    cd $srcWorkingDirectory/$projectRootDirectory
    set -x
    az webapp up \
        --name $webAppName \
        --output none \
        &>/dev/null #swallow all the output
)
