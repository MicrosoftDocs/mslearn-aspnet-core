(
    echo "${newline}${headingStyle}Provisioning server for Azure Database for PostgreSQL...${azCliCommandStyle}"
    set -x
    az postgres server create \
        --name $postgreSqlServerName \
        --admin-user $postgreSqlUsername \
        --admin-password $postgreSqlPassword \
        --sku-name $postgreSqlSku \
        --ssl-enforcement disabled \
        --version 11 \
        --location "west us" \
        --output none
)
(
    echo "${newline}${headingStyle}Provisioning PostgreSQL database...${azCliCommandStyle}"
    set -x
    az postgres db create \
        --name $postgreSqlDatabaseName \
        --server $postgreSqlServerName \
        --output none
)
(
    echo "${newline}${headingStyle}Adding Azure IP addresses to PostgreSQL database firewall rules...${azCliCommandStyle}"
    set -x
    az postgres server firewall-rule create \
        --name AllowAzureAccess \
        --start-ip-address 0.0.0.0 \
        --end-ip-address 0.0.0.0 \
        --server $postgreSqlServerName \
        --output none
)
echo