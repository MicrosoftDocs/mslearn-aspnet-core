#!/bin/bash

echo "Deleting service principal(s)..."

while IFS= read -r appId
do
    echo "> az ad sp delete --id $appId"
    az ad sp delete --id $appId
done < <(az ad sp list --show-mine --query "[?contains(displayName,'eShop-Learn-AKS')].appId" --output tsv)

echo "Done!"