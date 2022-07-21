#!/bin/bash

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

if [ -f ../../create-acr-exports.txt ]
then
  eval $(cat ../../create-acr-exports.txt)
fi


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

echo "${newline}${bold}=========Deploy the WebStatus service==============${defaultTextStyle}${newline}"
./deploy-application.sh --registry eshoplearn --hostip $ipAddress --charts webstatus

echo "${newline}${bold}=========Deploy the Identity.API service==============${defaultTextStyle}${newline}"
./deploy-application.sh --registry $ESHOP_REGISTRY --hostip $ipAddress --charts identity

echo "${newline}${bold}=========Deploy the WebSalesAgg service==============${defaultTextStyle}${newline}"
./deploy-application.sh --registry $ESHOP_REGISTRY --hostip $ipAddress --charts websalesagg

echo "${newline}${bold}Done!${defaultTextStyle}${newline}"