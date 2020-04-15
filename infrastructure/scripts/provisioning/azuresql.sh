(
    echo "${newline}${headingStyle}Provisioning Azure SQL Database Server...${azCliCommandStyle}"
    set -x
    az sql server create \
        --name $sqlServerName \
        --admin-user $sqlUsername \
        --admin-password $sqlPassword \
        --location "west us" \
        --output none
)
(
    echo "${newline}${headingStyle}Provisioning Azure SQL Database...${azCliCommandStyle}"
    set -x
    az sql db create \
        --name $databaseName \
        --server $sqlServerName \
        --service-objective BASIC \
        --output none
)
(
    echo "${newline}${headingStyle}Adding Azure IP addresses to Azure SQL Database firewall rules...${azCliCommandStyle}"
    set -x
    az sql server firewall-rule create \
        --name AllowAzureAccess \
        --start-ip-address 0.0.0.0 \
        --end-ip-address 0.0.0.0 \
        --server $sqlServerName \
        --output none
)
echo