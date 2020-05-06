(
    echo "${newline}${headingStyle}Provisioning Azure Key Vault...${azCliCommandStyle}"
    set -x
    az keyvault create \
        --name $keyVaultName \
        --enable-soft-delete \
        --output none
)
(
    echo "${newline}${headingStyle}Assigning managed service identity for web app...${azCliCommandStyle}"
    set -x
    az webapp identity assign \
        --name $webAppName \
        --output none
)
(
    echo "${newline}${headingStyle}Adding managed service identity to Key Vault...${azCliCommandStyle}"
    webAppPrincipalId=$(az webapp identity show --name $webAppName --query principalId --output tsv)
    set -x
    az keyvault set-policy \
        --name $keyVaultName \
        --object-id $webAppPrincipalId \
        --secret-permissions get list \
        --output none
)