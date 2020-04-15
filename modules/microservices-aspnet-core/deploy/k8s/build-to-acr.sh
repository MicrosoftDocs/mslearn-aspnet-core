#!/bin/bash

if [ -f ~/clouddrive/source/create-acr-exports.txt ]
then
  eval $(cat ~/clouddrive/source/create-acr-exports.txt)
fi

registry=${ESHOP_REGISTRY}
platform=${PLATFORM:-linux}
tag=${TAG:-latest}

if [ -z "$registry" ]
then
    echo "Must set and export environment variable called ESHOP_REGISTRY with the ACR login server"
    exit 1
fi

export REGISTRY=$registry
export TAG=$tag
export PLATFORM=$platform

pushd ../..

echo
echo "Building and publishing docker images to $REGISTRY"

# The Dockerfile.acr files are optimized for building to ACR, where you can't take advatage of image layer caching

echo
echo "Building image \"coupon.api\"..."
az acr build -r $ESHOP_ACRNAME -t $ESHOP_REGISTRY/coupon.api:linux-latest -f src/Services/Coupon/Coupon.API/Dockerfile.acr .
echo
echo "Building image \"webspa\"..."
az acr build -r $ESHOP_ACRNAME -t $ESHOP_REGISTRY/webspa:linux-latest -f src/Web/WebSPA/Dockerfile.acr .

popd
