#!/usr/bin/env bash
set -x -e

buildnumber=${4-$(date -u +"%y%m%d%H%M")}

docker build --no-cache -t "$1"/kudulite:"$buildnumber" kudu
docker tag "$1"/kudulite:"$buildnumber" "$1"/kudulite:latest

#docker login -u "$2" -p "$3"

#docker push "$1"/kudulite:"$buildnumber"
#docker push "$1"/kudulite:latest

#docker logout
