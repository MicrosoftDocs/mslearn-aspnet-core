#!/bin/bash

if [ -f ~/clouddrive/aspnet-learn/create-acr-exports.txt ]
then
  eval $(cat ~/clouddrive/aspnet-learn/create-acr-exports.txt)
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

echo
echo "Building and publishing docker images to $REGISTRY..."

echo
echo "Building image \"coupon.api\"..."
echo "az acr build -r $ESHOP_ACRNAME -t $ESHOP_REGISTRY/coupon.api:linux-latest -f src/Services/Coupon/Coupon.API/Dockerfile ."
az acr build -r $ESHOP_ACRNAME -t $ESHOP_REGISTRY/coupon.api:linux-latest -f src/Services/Coupon/Coupon.API/Dockerfile .

echo
echo "Building image \"webspa\"..."
echo "az acr build -r $ESHOP_ACRNAME -t $ESHOP_REGISTRY/webspa:linux-latest -f src/Web/WebSPA/Dockerfile.acr ."
# This Dockerfile.acr file is optimized for building to ACR, where you can't take advatage of image layer caching
az acr build -r $ESHOP_ACRNAME -t $ESHOP_REGISTRY/webspa:linux-latest -f src/Web/WebSPA/Dockerfile.acr .

echo "Done building and publishing docker images to $REGISTRY!"