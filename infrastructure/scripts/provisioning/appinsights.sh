(
    echo "${newline}${headingStyle}Provisioning Azure Monitor Application Insights...${azCliCommandStyle}"
    set -x
    az resource create \
        --resource-type microsoft.insights/components \
        --name $appInsightsName \
        --is-full-object \
        --properties '{"kind":"web","location":"southcentralus","properties":{"Application_Type":"web"}}' \
        --output none
)
echo

# Create an API Key for App Insights
# There is no Az CLI command for this, so we must use the REST API.
appInsightsDetails=$(az resource show --resource-type microsoft.insights/components --name $appInsightsName)
token=$(az account get-access-token --output tsv --query accessToken)
aiPath=$"/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/microsoft.insights/components/$appInsightsName"
body=$"{\"name\":\"$appInsightsName-ApiKey\",\"linkedReadProperties\":[\"$aiPath/api\"]}"
len=$(expr length $body)
url="https://management.azure.com$aiPath/apikeys?api-version=2015-05-01"

echo "${newline}${headingStyle}Using Azure REST API to set an API Key in Application Insights. The command looks like this (abridged for brevity):"
echo "${defaultTextStyle}curl -X POST \\${newline}" \
        "-H \"Authorization: Bearer <token>\" \\${newline}" \
        "-H \"Content-Type: application/json\" \\${newline}" \
        "-H \"Content-Length: <content length>\" \\${newline}" \
        "-s \\${newline}" \
        "<azure management endpoint url> \\${newline}" \
        "-d \"{\\\"name\\\":\\\"<api key name>\\\",\\\"linkedReadProperties\\\":[\\\"<app insights resource uri>/api\\\"]}\""

result=$(curl -X POST \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Content-Length: $len" \
        -s \
        $url \
        -d $body)
apiKey=$(echo $result | jq -r '.apiKey')
appId=$(echo $appInsightsDetails | jq -r '.properties.AppId')
instrumentationKey=$(echo $appInsightsDetails | jq -r '.properties.InstrumentationKey')

echo $apiKey > $apiKeyTempFile
echo $appId > $appIdTempFile
echo $instrumentationKey > $instrumentationKeyTempFile