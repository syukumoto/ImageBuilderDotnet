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
declare -r TEST_IMAGE_REPO_NAME="appsvcdevacr.azurecr.io"
declare -r ACR_BUILD_IMAGES_ARTIFACTS_FILE="$SYSTEM_ARTIFACTS_DIR/builtImages.txt"


function buildAndTagStage()
{
	local dockerFile="$1"
	local stageName="$2"
	local stageTagName="$ACR_PUBLIC_PREFIX/$2"

	echo
	echo "Building stage '$stageName' with tag '$stageTagName'..."
	docker build --target $stageName -t $stageTagName $ctxArgs $BASE_TAG_BUILD_ARGS -f "$dockerFile" .
}

function buildDockerImage() {
        
        local stacksFilePath="$CONFIG_DIR/stacks.txt"       
	
        while IFS= read -r STACK || [[ -n $STACK ]]
	do
            while IFS= read -r STACK_VERSION || [[ -n $STACK_VERSION ]]
            do
               local buildImageTag="${TEST_IMAGE_REPO_NAME}/${STACK}:${STACK_VERSION}_123"
               local appSvcDockerfilePath="${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}/Dockerfile" 
               ls "${SYSTEM_ARTIFACTS_DIR}"
               ls "${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}/"
               echo
               echo "Building test image with tag '$buildImageTag' and file $appSvcDockerfilePath..."
               echo docker build -t "$buildImageTag" -f "$appSvcDockerfilePath" .
               docker build -t "$buildImageTag" -f "$appSvcDockerfilePath" .         
            done < "$CONFIG_DIR/${STACK}Versions.txt"
        done < "$stacksFilePath"
}

buildDockerImage
