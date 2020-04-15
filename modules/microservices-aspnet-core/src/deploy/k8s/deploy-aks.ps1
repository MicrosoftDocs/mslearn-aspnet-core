$acr=$env:REGISTRY
$lbIp=$env:LBIP

if ($args.Length -eq 0) {
  $charts=Get-ChildItem -Directory .\helm-simple
}else {
  $charts=$args
}

ForEach ($chart in $charts) {
  helm.exe install eshop-$chart --set registry=$acr --set aksLB=$lbIp helm-simple\$chart
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
Write-Output "You can begin exploring these services (when available):"
Write-Output "- Centralized logging       : http://$lbIp/seq/#/events?autorefresh (See transient failures during startup)"
Write-Output "- General application status: http://$lbIp/webstatus/ (See overall service status)"
Write-Output "- Web SPA application       : http://$lbIp/"
Write-Output ""

