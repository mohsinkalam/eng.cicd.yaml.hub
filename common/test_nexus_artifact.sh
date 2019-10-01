#!/bin/bash
###################################################
# This script is used to test nexus artifacts existance.
# Parameter is ARTIFACT_PATH e.g. if artifact URL is 
# https://nexus.devfactory.com/repository/avolin-tradebeam-gtm-snapshots/avolin/tradebeam-gtm/CI.gtm.32/tradebeam-gtm-CI.gtm.32.zip
# Artifact path would be : avolin-tradebeam-gtm-snapshots/avolin/tradebeam-gtm/CI.gtm.32/tradebeam-gtm-CI.gtm.32.zip
###################################################


ARTIFACT_PATH=${1}

ARTIFACT_URL=https://nexus.devfactory.com/repository/${ARTIFACT_PATH}

echo "Artifact URL to test : ${ARTIFACT_URL}"
request_cmd="$(curl --head --silent ${ARTIFACT_URL})"
echo "Full response body : $request_cmd"
http_status=$(echo "$request_cmd" | grep HTTP |  awk '{print $2}')
echo "HTTP Status : $http_status"
output_response=$(echo "$request_cmd")
if [ "$http_status" != "200" ]; then
    # handle error
    echo "Return code is $http_status"
    exit 1;
fi

echo "Artifact exists on nexus"