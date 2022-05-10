#!/bin/bash

# This script takes a list of directories to clone from 
# the mslearn-aspnet-core repo. Since it's a subset of 
# the repo, it's referred to as a "sparse checkout."
# An environment variable named $gitBranch should be set
# and contain the branch to be used, e.g., "live" or "master".

# constants
DIR="aspnet-learn"
REPOS="https://github.com/ecortijo/mslearn-aspnet-core"
BRANCH=$gitBranch

# input parameters
CHECKOUT_DIRS=( "$@" )

mkdir -p $DIR
if [ -d "$DIR" ]; then
    cd $DIR
    git init --quiet
    git remote add -f origin $REPOS
    git fetch --all --quiet
    git config core.sparseCheckout true
    if [ -f .git/info/sparse-checkout ]; then
        rm .git/info/sparse-checkout
    fi

    for i in ${CHECKOUT_DIRS[@]}; do
        echo ${i} >> .git/info/sparse-checkout
    done

    git checkout $BRANCH --quiet
    git merge --ff-only origin/$BRANCH --quiet

    # Current structure is ~/aspnet-learn/modules/persist-data-ef-core/src (for example).
    # This is a longer path than we'd like for the best experience,
    # so let's move the src and setup directories up a level
    pushd ${CHECKOUT_DIRS[0]}
    cd ../..
    DELETE_DIR=$PWD 
    popd
    for i in ${CHECKOUT_DIRS[@]}; do
        mv ${i} ./
        while [ ! $? -eq 0 ]; do
            echo "Couldn't move files to working directory. Retrying..."
            sleep 5
            mv ${i} ./
        done
    done
    rm $DELETE_DIR -rf
fi
