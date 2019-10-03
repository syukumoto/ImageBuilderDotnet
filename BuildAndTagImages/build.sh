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
	# 1.0 -> uses Oryx Base Image mcr.microsoft.com/oryx/dotnetcore:1.0-$BASE_IMAGE_VERSION_STREAM_FEED
	while IFS= read -r STACK || [[ -n $STACK ]]
	do
            while IFS= read -r STACK_VERSION || [[ -n $STACK_VERSION ]]
            do
               local buildImageTag="${TEST_IMAGE_REPO_NAME}/${STACK}:${STACK_VERSION}_123"
               local appSvcDockerfilePath="${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}/Dockerfile"   
               echo
               echo "Building test image with tag '$buildImageTag' and file $appSvcDockerfilePath..."
               docker build -t $builtImageTag -f $appSvcDockerfilePath .         
            done < "$CONFIG_DIR/${STACK}Versions.txt"
        done < "$stacksFilePath"
}

buildDockerImage
