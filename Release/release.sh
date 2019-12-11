#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# This script publishes images to dockerhub for Azure App Services on Linux
# --------------------------------------------------------------------------------------------

set -e

# Set BUILD to the images' build number you wish to push to APP_SVC_DOCKER_REPO
declare -r BUILD="20191114.1"

declare -r DEFAULT_WORKING_DIRECTORY="$1" # $(System.DefaultWorkingDirectory)
declare -r APP_SVC_DOCKER_REPO="appsvc"
declare -r APP_SVC_DEV_ACR="appsvcdevacr.azurecr.io"

function tagACRImagesToDockerHub()
{
    echo "Tagging acr images to dockerhub"
    echo "Build number is $BUILD"

    while IFS=, read -r STACK ||  [[ -n $STACK ]]
	do
        echo "Processing $STACK tags"
        while IFS=, read -r TAG ||  [[ -n $TAG ]]
        do
            if [[ $TAG == *$BUILD ]]
            then
                # Tag images from APP_SVC_DEV_ACR to APP_SVC_DOCKER_REPO
                local imageName="${STACK}:${TAG}"
                local acrImage="${APP_SVC_DEV_ACR}/${imageName}"
                local dockerHubImage="${APP_SVC_DOCKER_REPO}/${imageName}"
                echo "Pulling from acr. Image: $acrImage"
                docker pull ${acrImage}
                echo "Tagging image"
                docker tag ${acrImage} ${dockerHubImage}
                echo "Pushing image to $dockerHubImage"
                docker push ${dockerHubImage}
            fi
        done < "$DEFAULT_WORKING_DIRECTORY/tags/$STACK"
    done < "$DEFAULT_WORKING_DIRECTORY/tags_list"
}

tagACRImagesToDockerHub

