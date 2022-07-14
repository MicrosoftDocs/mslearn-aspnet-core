#!/bin/bash

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

if [ -f ../../deploy-application-exports.txt ]
then
  eval $(cat ../../deploy-application-exports.txt)
fi

# After the initial deployment, an ACR resource is created. This reads in the ACR name for subsequent deployments.
if [ -f ../../create-acr-exports.txt ]
then
  eval $(cat ../../create-acr-exports.txt)
fi


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
defaultRegistry="eshoplearn"

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

if [ -z "$hostName" ]
then
    echo
    echo "Couldn't resolve the host name!"
    echo "Either use the --hostip (for IP addresses), or --hostname (for DNS names), or"
    echo "run the \"eval $(cat ~/clouddrive/aspnet-learn/deploy-application-exports.txt)\" command to the values from the initial deployment."
    echo
    exit 1
fi

if [ -z "$protocol" ]
then
    protocol="http"
fi

if [ "$certificate" == "self-signed" ]
then
    pushd ./certificates >/dev/null
    ./create-self-signed-certificate.sh
    popd >/dev/null

    echo
    echo "Deploying a development self-signed certificate"

    ./deploy-secrets.sh
fi

echo "export ESHOP_LBIP=$ESHOP_LBIP" > deploy-application-exports.txt
echo "export ESHOP_HOST=$hostName" >> deploy-application-exports.txt
echo "export ESHOP_REGISTRY=$ESHOP_REGISTRY" >> deploy-application-exports.txt
mv deploy-application-exports.txt ../..

if [ "$charts" == "" ]
then
    installedCharts=$(helm list -qf $appPrefix-)
    if [ "$installedCharts" != "" ]
    then
        echo "Uninstalling Helm charts..."
        helmCmd="helm delete $installedCharts"
        echo "${newline} > ${genericCommandStyle}$helmCmd${defaultTextStyle}${newline}"
        eval $helmCmd
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
            helmCmd="helm delete $installedChart"
            echo "${newline} > ${genericCommandStyle}$helmCmd${defaultTextStyle}${newline}"
            eval $helmCmd
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
    helmCmd="helm install eshoplearn-$chart \"$chartsFolder/$chart\" --set registry=$registry --set imagePullPolicy=Always --set useHostName=$useHostName --set host=$hostName --set protocol=$protocol"
    echo "${newline} > ${genericCommandStyle}$helmCmd${defaultTextStyle}${newline}"
    eval $helmCmd
done

echo
echo "Helm charts deployed!"
echo 
echo "${newline} > ${genericCommandStyle}helm list${defaultTextStyle}${newline}"
helm list

echo "Displaying Kubernetes pod status..."
echo 
echo "${newline} > ${genericCommandStyle}kubectl get pods${defaultTextStyle}${newline}"
kubectl get pods

echo "The eShop-Learn application has been deployed to \"$protocol://$hostName\" (IP: $ESHOP_LBIP)." > deployment-urls.txt
echo "" >> deployment-urls.txt
echo "You can begin exploring these services (when ready):" >> deployment-urls.txt
echo "- Centralized logging       : $protocol://$hostName/seq/#/events?autorefresh (See transient failures during startup)" >> deployment-urls.txt
echo "- General application status: $protocol://$hostName/webstatus/ (See overall service status)" >> deployment-urls.txt
echo "- Web SPA application       : $protocol://$hostName/" >> deployment-urls.txt
echo "${newline}" >> deployment-urls.txt

mv deployment-urls.txt ../../
