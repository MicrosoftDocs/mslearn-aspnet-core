#!/bin/bash

# Color theming
. <(cat ./theme.sh)

# AZ CLI check
. <(cat ./azure-cli-check.sh)

pushd ../.. >/dev/null

if [ -f create-acr-exports.txt ]
then
  eval $(cat create-acr-exports.txt)
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
couponCmd="az acr build --registry $ESHOP_ACRNAME --image $ESHOP_REGISTRY/coupon.api:linux-net6-initial --file ./src/Services/Coupon/Coupon.API/Dockerfile ."
echo "> $couponCmd"
eval $couponCmd

if [ ! $? -eq 0 ]
then
    echo "Error building Coupon.API!"
    exit 1
fi

echo
echo "Building image \"webspa\"..."
# This Dockerfile.acr file is optimized for building to ACR, where you can't take advatage of image layer caching
webspaCmd="az acr build --registry $ESHOP_ACRNAME --image $ESHOP_REGISTRY/webspa:linux-net6-initial --file ./src/Web/WebSPA/Dockerfile.acr ."
echo "> $webspaCmd"
eval $webspaCmd

if [ ! $? -eq 0 ]
then
    echo 
    echo "Error building WebSPA!"
    exit 1
else
  echo
  echo "Done building and publishing docker images to $REGISTRY!"
fi

popd >/dev/null
