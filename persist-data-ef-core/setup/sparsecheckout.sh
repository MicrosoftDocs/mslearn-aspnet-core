#!/bin/bash

# constants
DIR="contoso-pets"
REPOS="https://github.com/MicrosoftDocs/mslearn-aspnet-core"
BRANCH="master"

# input parameters
CHECKOUT_DIRS=( "$@" )
#MODULE_DIR=$CHECKOUT_DIRS[0]/..

mkdir -p $DIR
if [ -d "$DIR" ]; then
    cd $DIR
    git init
    git remote add -f origin $REPOS
    git fetch --all
    git config core.sparseCheckout true
    if [ -f .git/info/sparse-checkout ]; then
        rm .git/info/sparse-checkout
    fi

    for i in ${CHECKOUT_DIRS[@]}; do
        echo ${i} >> .git/info/sparse-checkout
    done

    git checkout $BRANCH
    git merge --ff-only origin/$BRANCH

    # Current structure is ~/contoso-pets/persist-data-ef-core/src (for example).
    # This is a longer path than we'd like for the best experience,
    # so let's move the src and setup directories up a level
    pushd $CHECKOUT_DIRS[0]
    cd ..
    DELETE_DIR=$PWD 
    popd
    for i in ${CHECKOUT_DIRS[@]}; do
        mv ${i} ./
    done
    rm $DELETE_DIR
fi
