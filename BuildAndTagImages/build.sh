#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# This script builds Docker Images for all stacks on Azure App Service on Linux.
# --------------------------------------------------------------------------------------------

set -e


# Directory for Generated Docker Files
declare -r SYSTEM_ARTIFACTS_DIR="$1"
declare -r APP_SVC_BRANCH_PREFIX="$2"           # appsvc, appsvctest
declare -r CONFIG_DIR="$3"
declare -r PIPELINE_BUILD_NUMBER="$4"
declare -r STACK="$5"
declare -r BUILD_REASON="$6"
declare -r FILES_ROOT_PATH="$7"
declare -r IMG_TAG="$8"
declare -r WAWS_IMAGE_REPO_NAME="wawsimages.azurecr.io"
declare -r ACR_BUILD_IMAGES_ARTIFACTS_FILE="$SYSTEM_ARTIFACTS_DIR/builtImages.txt"
declare -r STACK_VERSION_TO_BUILD=$9

function displayArtifactsDir()
{
    local artifactsDir=$1
    echo "Listing artifacts dir :"
    echo "--------------------------"
    ls $artifactsDir
    echo 
}

function displayStackDir()
{
    local stacksDir=$1
    echo "Listing stacks dir :"
    echo "--------------------------"
    ls $stacksDir
    echo 
}

function displayInformationRegardingImageToBeBuilt()
{
    local tag=$1
    local dockerFilePath=$2
    echo "Building test image with "
    echo "--------------------------"
    echo "Tag           : $BuildVerRepoTag "
    echo "DockerFile    : $appSvcDockerfilePath"
    echo
}

function buildDockerImage() 
{
    if [ -f "$CONFIG_DIR/${STACK}VersionTemplateMap.txt" ]; then
        while IFS=, read -r STACK_VERSION BASE_IMAGE STACK_VERSION_TEMPLATE_DIR STACK_TAGS || [[ -n $STACK_VERSION ]] || [[ -n $BASE_IMAGE ]] || [[ -n $STACK_VERSION_TEMPLATE_DIR ]] || [[ -n $STACK_TAGS ]]
        do
            if [[ -z $STACK_VERSION_TO_BUILD || $STACK_VERSION_TO_BUILD == $STACK_VERSION ]];
            then
                echo "Stack Tag     : ${STACK_TAGS}"
                echo "Stack Version : $STACK_VERSION"
                echo 

                IFS='|' read -ra STACK_TAGS_ARR <<< "$STACK_TAGS"
                for TAG in "${STACK_TAGS_ARR[@]}"
                do
                    local STACK_MOD=$STACK
                    if [[ $STACK = "php-xdebug" ]]
                    then
                        STACK_MOD="php"
                    fi

                    if [[ $STACK = "wordpress" ]]
                    then
                        STACK_MOD="wordpress-alpine-php"
                    fi

                    local TAG_MOD="${TAG}_${PIPELINE_BUILD_NUMBER}"
                    if [[ $STACK = "wordpress" && ( $TAG = "latest"  ||  $TAG = "latest_7.4" ) ]]; then
                        TAG_MOD="${TAG}"
                    fi

                    # Build Image Tags are converted to lower case because docker doesn't accept upper case tags
                    local MCRRepoTagUpperCase="${WAWS_IMAGE_REPO_NAME}/public/appsvc/${STACK_MOD}:${TAG_MOD}"
                    local MCRRepoTag="${MCRRepoTagUpperCase,,}"
                    local appSvcDockerfilePath="${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}/Dockerfile"
                    local BuildVerRepoTagUpperCase="${WAWS_IMAGE_REPO_NAME}/${STACK_MOD}:${TAG_MOD}"
                    local BuildVerRepoTag="${BuildVerRepoTagUpperCase,,}"

                    displayArtifactsDir "${SYSTEM_ARTIFACTS_DIR}"
                    displayStackDir "${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}"                    

                    cd "${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}"                    
                    displayInformationRegardingImageToBeBuilt $BuildVerRepoTag $appSvcDockerfilePath

                    # php-xdebug depends of published images
                    if [ "$BUILD_REASON" != "PullRequest" ] || [ "$STACK" != "php-xdebug" ]; then
                        echo docker build -t "$BuildVerRepoTag" -f "$appSvcDockerfilePath" .
                        docker build -t "$BuildVerRepoTag" -f "$appSvcDockerfilePath" .
                    elif [ "$BUILD_REASON" != "PullRequest" ] && [ "$STACK" == "php-xdebug" ]; then
                        # poll until php image is published
                        BASE_TAG=`head -n 1 Dockerfile | sed 's/FROM //g'`
                        PULL_OUTPUT=`docker pull $BASE_TAG`
                        LOOP_COUNTER=0;
                        while [[ $PULL_OUTPUT != *"up to date"* ]] && [ $LOOP_COUNTER -le 60 ]; do
                            sleep 1m
                            PULL_OUTPUT=$(docker pull $BASE_TAG)
                            LOOP_COUNTER=$LOOP_COUNTER+1
                        done;
                        echo docker build -t "$BuildVerRepoTag" -f "$appSvcDockerfilePath" .
                        docker build -t "$BuildVerRepoTag" -f "$appSvcDockerfilePath" .
                    fi

                    if [ "$BUILD_REASON" != "PullRequest" ]; then
                        docker push $BuildVerRepoTag
                        docker tag $BuildVerRepoTag $MCRRepoTag
                        docker push $MCRRepoTag
                    fi

                    echo $MCRRepoTag >> $SYSTEM_ARTIFACTS_DIR/${STACK}builtImageList
                done
            fi
            
        done < "$CONFIG_DIR/${STACK}VersionTemplateMap.txt"
    fi
}

buildDockerImage
