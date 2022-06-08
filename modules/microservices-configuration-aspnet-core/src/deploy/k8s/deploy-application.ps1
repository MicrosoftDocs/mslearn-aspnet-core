param (
    # Deployment type (local/remote)
    [Parameter(Mandatory=$true)][string]$deploymentType,
    # Protocol (http/https)
    [Parameter(Mandatory=$true)][string]$protocol="http",
    # Kubernetes host name
    [Parameter(Mandatory = $false)][string]$hostName,
    # Registry
    [Parameter(Mandatory = $false)][string]$registry,
    # chart list
    [Parameter(Mandatory = $false)][string[]]$charts
)

# This is a dev/test script, doesn't deploy the certificates

if ("local,aks" -split "," -notcontains $deploymentType) {
    Write-Error "Must specify either ""local"" or ""aks"" as the deployment type!"
    exit 1
}

if ("http,https" -split "," -notcontains $protocol) {
    Write-Error "Must specify either ""http"" or ""https"" as the protocol to use!"
    exit 1
}

$k8sContext = $(kubectl config current-context)
$localK8s = "docker-desktop,docker-for-desktop" -split "," -contains $k8sContext
$appPrefix = "eshoplearn"
$chartsFolder = ".\helm-simple"
$defaultRegistry = "eshoplearn"

if ($deploymentType -eq "local") {
    if (!$localK8s) {
        Write-Error "Current Kubernetes context ($k8sContext) is not local!"
        exit 1
    }

    if ($hostName -eq "") {
        if ( $protocol -eq "http") {
            $hostName = "localhost"
        }
        else {
            $hostName = "$appPrefix.local"
        }
    }

    $imagePullPolicy = "Never"
} 
else {
    if ($localK8s) {
        Write-Error "Current Kubernetes context ($k8sContext) is local!"
        exit 1
    }

    if ($hostName -eq "") {
        Write-Error "Must specify the hostName for a remote reployment!"
        exit 1
    }

    $imagePullPolicy = "Always"
}

if ("$registry" -eq "") {
    $registry = $defaultRegistry
}

if (!"$hostName" -match "^[0-9]{1,3}(\.[0-9]{1,3}){3}$") {
    $useHostName = true
}

Write-Output ""
Write-Output "Deploying Helm charts from registry \"$registry\" to ""${protocol}://$hostName""..."

if ("$charts" -eq "") {
    Write-Output ""
    Write-Output "Uninstalling Helm charts..."
    helm delete $(helm list -qf $appPrefix)
} 
else {
    $chartArray = $charts -split ","
    ForEach ($chart in $chartArray) {
        Write-Output ""
        Write-Output "Uninstalling chart ""$chart""..."
        helm delete $(helm list -qf $appPrefix-$chart)
    }
}

if ("$charts" -eq "") {
    $chartArray = Get-ChildItem -Directory $chartsFolder
} 

ForEach ($chart in $chartArray) {
    Write-Output ""
    Write-Output "Installing chart ""$chart""..."
    helm install $appPrefix-$chart `
        --set registry=$registry `
        --set imagePullPolicy=$imagePullPolicy `
        --set useHostName=$useHostName `
        --set host=$hostName `
        --set protocol=$protocol `
        $chartsFolder\$chart
}

# install charts

Write-Output ""
Write-Output "Helm charts deployed"
helm list

Write-Output ""
Write-Output "Pod status"
kubectl get pods

Write-Output ""
Write-Output "The eShop-Learn application has been deployed."
Write-Output ""
Write-Output "You can begin exploring these services (when ready):"
Write-Output "- Centralized logging       : ${protocol}://$hostName/seq/#/events?autorefresh (See transient failures during startup)"
Write-Output "- General application status: ${protocol}://$hostName/webstatus/ (See overall service status)"
Write-Output "- Web SPA application       : ${protocol}://$hostName/"
Write-Output ""
