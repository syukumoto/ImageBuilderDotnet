#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# This script generates DOTNET Core Images for Azure App Service on Linux,
# It uses Microsoft Oryx as the base Image.
# --------------------------------------------------------------------------------------------

set -e

declare -r DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

declare -r ORYX_BASE_IMAGE_NAME="$1"
declare -r ORYX_VERSION_STREAM_FEED="$2"  #
declare -r APP_SVC_BRANCH_PREFIX="$3"     # appsvc, appsvctest
declare -r APPSVC_DOTNETCORE_REPO="$4"    # https://github.com/Azure-App-Service/dotnetcore.git

declare -r APP_SVC_REPO_DIR="$DIR/GitRepo"
declare -r APP_SVC_REPO_BRANCH="dev"
declare -r STACK_NAME="dotnetcore"


function generateDockerFiles()
{
	local versionsFile="$1"
        local dockerTemplateDir="$2"
        local baseImageName="$3"
        local baseImageVersionStreamFeed="$4"

	# Example line:
	# 1.0 -> uses Oryx Base Image mcr.microsoft.com/oryx/dotnetcore:1.0-$ORYX_VERSION_STREAM_FEED
	while IFS= read -r STACK_VERSION || [[ -n $STACK_VERSION ]]
	do
        FINAL_IMAGE_NAME="$(echo -e "${APP_SVC_BRANCH_PREFIX}/${STACK_NAME}:${STACK_VERSION}_${baseImageVersionStreamFeed}" | sed -e 's/^[[:space:]]*//')"
        
        # Oryx Image
        BASE_IMAGE_NAME="$baseImageName:$baseImageVersionStreamFeed"
        VERSION_DIRECTORY="${APP_SVC_REPO_DIR}/${STACK_VERSION}"
        TARGET_DOCKERFILE="${VERSION_DIRECTORY}/Dockerfile"
        
        echo "Generating Dockerfile for image '$FINAL_IMAGE_NAME' in directory '$VERSION_DIRECTORY'..."

        # Remove Existing Version directory, eg: GitRepo/1.0 to replace with realized files
        rm -rf "$VERSION_DIRECTORY"
        mkdir -p "$VERSION_DIRECTORY"
        cp -R $dockerTemplateDir/* "$VERSION_DIRECTORY"

        # Replace placeholders
		 sed -i "s/BASE_IMAGE_NAME_PLACEHOLDER/$BASE_IMAGE_NAME/g" "$TARGET_DOCKERFILE"

		# Copy Hosting Start App
        cp "$DIR/SampleApps/$STACK_VERSION/bin.zip" "${VERSION_DIRECTORY}/"

	done < "$versionsFile"
}

function pullAppSvcRepo()
{
    echo "Cloning App Service DOTNETCORE Repository in $APP_SVC_REPO_DIR"
    git clone $APPSVC_DOTNETCORE_REPO $APP_SVC_REPO_DIR
    cho "Cloning App Service DOTNETCORE Repository in $APP_SVC_REPO_DIR"
    cd $APP_SVC_REPO_DIR
    echo "Checking out branch $APP_SVC_REPO_BRANCH"
    git checkout $APP_SVC_REPO_BRANCH
    chmod -R 777 *
}

pullAppSvcRepo
generateDockerFiles "$DIR/dotnetCoreVersions.txt" "$DIR/debian-9" $ORYX_BASE_IMAGE_NAME $ORYX_VERSION_STREAM_FEED
