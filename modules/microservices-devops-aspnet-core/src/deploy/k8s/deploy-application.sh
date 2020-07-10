#!/bin/bash
registry=$REGISTRY
eshopRegistry=${ESHOP_REGISTRY}

if [ -z "$registry" ]&&[ ! -z "$eshopRegistry" ]
then
    registry=$eshopRegistry
fi

while [ "$1" != "" ]; do
    case $1 in
        --registry)                     shift
                                        registry=$1
                                        ;;
        --hostname)                     shift
                                        hostName=$1
                                        ;;
        --hostip)                       shift
                                        hostIp=$1
                                        ;;
        --protocol)                     shift
                                        protocol=$1
                                        ;;
        --certificate)                  shift
                                        certificate=$1
                                        ;;
        --charts)                       shift
                                        charts=$1
                                        ;;
       * )                              echo "Invalid param: $1"
                                        exit 1
    esac
    shift
done

appPrefix="eshoplearn"
chartsFolder="./helm-simple"
defaultRegistry="eshopdev"

if [ -z "$registry" ]
then
    registry=$defaultRegistry
    echo
    echo "Using default registry \"$defaultRegistry\" for images to deploy to AKS."
    echo "To change this, set and export the environment variable REGISTRY with registry/ACR login server or use the --registry parameter."
    echo
fi

if [ ! -z "$hostIp" ]
then
    hostName=$hostIp
fi

if [ -z "$hostName" ]
then
    hostName=$ESHOP_LBIP
elif [ -z "$hostIp" ]
then
    useHostName=true
fi

if [ -z "$protocol" ]
then
    protocol="http"
fi

if [ "$certificate" == "self-signed" ]
then
    pushd ./certificates
    ./create-self-signed-certificate.sh
    popd

    echo
    echo "Deploying a development self-signed certificate"

    ./deploy-secrets.sh
fi

echo "export ESHOP_LBIP=$ESHOP_LBIP" > deploy-application-exports.txt
echo "export ESHOP_HOST=$hostName" >> deploy-application-exports.txt
echo "export ESHOP_REGISTRY=$ESHOP_REGISTRY" >> deploy-application-exports.txt

if [ "$charts" == "" ]
then
    installedCharts=$(helm list -qf $appPrefix-)
    if [ "$installedCharts" != "" ]
    then
        echo "Uninstalling Helm charts..."
        helm delete $installedCharts
    fi
    chartList=$(ls $chartsFolder)
else
    chartList=${charts//,/ }
    for chart in $chartList
    do
        installedChart=$(helm list -qf $appPrefix-$chart)
        if [ "$installedChart" != "" ]
        then
            echo
            echo "Uninstalling chart ""$chart""..."
            helm delete $installedChart
        fi
    done
fi

echo
echo "Deploying Helm charts from registry \"$registry\" to \"${protocol}://$hostName\"..."
echo "---------------------"

for chart in $chartList
do
    echo
    echo "Installing chart \"$chart\"..."
    helm install eshoplearn-$chart "$chartsFolder/$chart" \
        --set registry=$registry \
        --set imagePullPolicy=Always \
        --set useHostName=$useHostName \
        --set host=$hostName \
        --set protocol=$protocol 
done

echo
echo "Helm charts deployed"
helm list

echo
echo "Pod status"
kubectl get pods

echo
echo "The eShop-Learn application has been deployed to \"$protocol://$hostName\" (IP: $ESHOP_LBIP)."
echo
echo "You can begin exploring these services (when ready):"
echo "- Centralized logging       : $protocol://$hostName/seq/#/events?autorefresh (See transient failures during startup)"
echo "- General application status: $protocol://$hostName/webstatus/ (See overall service status)"
echo "- Web SPA application       : $protocol://$hostName/"

echo "eShop-Learn application deployed to \"$protocol://$hostName\" (IP: $ESHOP_LBIP)." > deploy-application-results.txt
echo "" >> deploy-application-results.txt
echo "- Logging       : $protocol://$hostName/seq/#/events?autorefresh" >> deploy-application-results.txt
echo "- General status: $protocol://$hostName/webstatus/" >> deploy-application-results.txt
echo "- Web SPA       : $protocol://$hostName/" >> deploy-application-results.txt

echo
echo "Run the following command to update the environment"
echo 'eval $(cat ~/clouddrive/source/deploy-application-exports.txt)'
echo

mv -f deploy-application-exports.txt ~/clouddrive/source/
mv -f deploy-application-results.txt ~/clouddrive/source/

