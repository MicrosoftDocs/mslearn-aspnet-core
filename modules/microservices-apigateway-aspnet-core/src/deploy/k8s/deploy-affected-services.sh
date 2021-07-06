#!/bin/bash

# Color theming
if [ -f ~/clouddrive/aspnet-learn/setup/theme.sh ]
then
  . <(cat ~/clouddrive/aspnet-learn/setup/theme.sh)
fi

if [ -f ~/clouddrive/aspnet-learn/create-acr-exports.txt ]
then
  eval $(cat ~/clouddrive/aspnet-learn/create-acr-exports.txt)
fi

pushd ~/clouddrive/aspnet-learn/src/deploy/k8s > /dev/null


while [ "$1" != "" ]; do
    case $1 in
        --ipAddress)                    shift
                                        ipAddress=$1
                                        ;;        
       * )                              echo "Invalid param: $1"
                                        exit 1
    esac
    shift
done

if [ -z $ipAddress ]
then
    echo "Must provide an ipAddress!"
    exit 1
fi

if [ -z "$ESHOP_REGISTRY" ]
then
    echo "One or more required environment variables are missing:"
    echo "- ESHOP_REGISTRY..: $ESHOP_REGISTRY"   
    exit 1
fi

echo "=========Deploy the WebStatus service=============="
./deploy-application.sh --registry eshopdev --hostip $ipAddress --charts webstatus

echo "=========Deploy the Identity.API service=============="
./deploy-application.sh --registry $ESHOP_REGISTRY --hostip $ipAddress --charts identity

echo "=========Deploy the WebSalesAgg service=============="
./deploy-application.sh --registry $ESHOP_REGISTRY --hostip $ipAddress --charts websalesagg

popd