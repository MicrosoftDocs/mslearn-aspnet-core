#!/bin/bash

# It's mandatory to have a REGISTRY environment variable
# If the REGISTRY is the same a ESHOP_REGISTRY


registry=$REGISTRY
platform=${PLATFORM:-linux}
tag=${TAG:-latest}

if [ -f ~/clouddrive/aspnet-learn/create-acr-exports.txt ]
then
  eval $(cat ~/clouddrive/aspnet-learn/create-acr-exports.txt)
fi

while [ "$1" != "" ]; do
    case $1 in
             --registry)                shift
                                        registry=$1
                                        ;;
        -t | --tag)                     shift
                                        tag=$1
                                        ;;
       * )                              echo "Invalid param: $1"
                                        exit 1
    esac
    shift
done

if [ -z "$registry" ]
then
    echo "Must set and export environment variable called REGISTRY with ACR login server or use --acr"
    exit 1
fi

export REGISTRY=$registry
export TAG=$tag
export PLATFORM=$platform

if [ ! -z "$ESHOP_REGISTRY" ]&&[ "$REGISTRY" == "$ESHOP_REGISTRY" ]
then
    if [ -z "$ESHOP_ACRUSER" ]||[ -z "$ESHOP_ACRPASSWORD" ]
    then
        echo "ERROR Missing ESHOP_ACRUSER ($ESHOP_ACRUSER) or ESHOP_ACRPASSWORD ($ESHOP_ACRPASSWORD)"
        exit 1
    fi

    echo
    echo "Logging in to ACR \"$REGISTRY\"..."
    docker login $ESHOP_REGISTRY -u $ESHOP_ACRUSER -p $ESHOP_ACRPASSWORD
fi

pushd ../..

echo
echo "Building docker images for $REGISTRY and tag $TAG and platform $PLATFORM"
docker-compose build

echo
echo "publishing docker images to $REGISTRY"
docker-compose push

popd