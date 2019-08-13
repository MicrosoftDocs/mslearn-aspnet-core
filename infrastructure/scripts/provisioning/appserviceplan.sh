(
    echo "${newline}${headingStyle}Provisioning App Service Plan...${azCliCommandStyle}"
    set -x
    az appservice plan create \
        --name $webPlanName \
        --sku F1 \
        --output none
)