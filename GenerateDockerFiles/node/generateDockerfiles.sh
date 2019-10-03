#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# This script generates Dockerfiles for ASP .NETCore Runtime Images for Azure App Service on Linux.
# --------------------------------------------------------------------------------------------

set -e

# Current Working Dir
declare -r DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
# Directory for Generated Docker Files
declare -r SYSTEM_ARTIFACTS_DIR="$1"
declare -r BASE_IMAGE_REPO_NAME="$2"                 # mcr.microsoft.com/oryx/dotnetcore
declare -r BASE_IMAGE_VERSION_STREAM_FEED="$3"  # Base Image Version; Oryx Version : 20190819.2
declare -r APP_SVC_BRANCH_PREFIX="$4"           # appsvc, appsvctest
declare -r APPSVC_DOTNETCORE_REPO="$5"          # https://github.com/Azure-App-Service/dotnetcore.git
declare -r APP_SVC_REPO_BRANCH="$6"             # dev
declare -r STACK_VERSIONS_FILE_PATH="$7"
declare -r STACK_NAME="node"
declare -r APP_SVC_REPO_DIR="$SYSTEM_ARTIFACTS_DIR/$STACK_NAME/GitRepo"



function generateDockerFiles()
{
    local dockerTemplateDir="$1"

	# Example line:
	# 1.0 -> uses Oryx Base Image mcr.microsoft.com/oryx/dotnetcore:1.0-$BASE_IMAGE_VERSION_STREAM_FEED
	while IFS= read -r STACK_VERSION || [[ -n $STACK_VERSION ]]
	do
        FINAL_IMAGE_NAME="$(echo -e "${APP_SVC_BRANCH_PREFIX}/${STACK_NAME}:${STACK_VERSION}_${BASE_IMAGE_VERSION_STREAM_FEED}" | sed -e 's/^[[:space:]]*//')"

        # Base Image
        BASE_IMAGE_NAME="$BASE_IMAGE_REPO_NAME:$BASE_IMAGE_VERSION_STREAM_FEED"
        CURR_VERSION_DIRECTORY="${APP_SVC_REPO_DIR}/${STACK_VERSION}"
        TARGET_DOCKERFILE="${CURR_VERSION_DIRECTORY}/Dockerfile"

        echo "Generating Dockerfile for image '$FINAL_IMAGE_NAME' in directory '$CURR_VERSION_DIRECTORY'..."

        # Remove Existing Version directory, eg: GitRepo/1.0 to replace with realized files
        rm -rf "$CURR_VERSION_DIRECTORY"
        mkdir -p "$CURR_VERSION_DIRECTORY"
        cp -R $dockerTemplateDir/* "$CURR_VERSION_DIRECTORY"

        # Replace placeholders, changing sed delimeter since '/' is used in path
        sed -i "s|BASE_IMAGE_NAME_PLACEHOLDER|$BASE_IMAGE_NAME|g" "$TARGET_DOCKERFILE"
        
        echo "Done."

	done < "$STACK_VERSIONS_FILE_PATH"
}

function pullAppSvcRepo()
{
    echo "Cloning App Service DOTNETCORE Repository in $APP_SVC_REPO_DIR"
    git clone $APPSVC_DOTNETCORE_REPO $APP_SVC_REPO_DIR
    echo "Cloning App Service DOTNETCORE Repository in $APP_SVC_REPO_DIR"
    cd $APP_SVC_REPO_DIR
    echo "Checking out branch $APP_SVC_REPO_BRANCH"
    git checkout $APP_SVC_REPO_BRANCH
    chmod -R 777 $APP_SVC_REPO_DIR
}

pullAppSvcRepo
generateDockerFiles "$DIR/debian-9"
