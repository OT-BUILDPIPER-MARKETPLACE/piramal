#!/bin/bash

# Load utility functions
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh


# Initialize variables
CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"
SLEEP_DURATION=${SLEEP_DURATION:-0}


logInfoMessage "Starting build process for code at ${CODEBASE_LOCATION}"


git config --global --add safe.directory /bp/workspace

# Ensure the working directory is set to the project root
cd "${CODEBASE_LOCATION:-/bp/workspace}" || {
  logErrorMessage "Failed to change directory to ${CODEBASE_LOCATION}"
  exit 1
}

# Extract repository URL from git configuration
cdefenseURL=$(grep -oP '(?<=url = ).*' .git/config)
if [ -z "$cdefenseURL" ]; then
  logErrorMessage "Failed to extract repository URL from .git/config"
  exit 1
fi

# Extract the username
username=$(grep 'url' .git/config | grep -oP '(?<=://)[^:]*')

# Extract the password/token
password=$(grep 'url' .git/config | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')

# Derive the application name from the repository URL
APP_NAME=$(basename "$cdefenseURL" .git)

if [ -z "$APP_NAME" ]; then
  logErrorMessage "Failed to derive application name from repository URL"
  exit 1
fi

# Retrieve Java version from pom.xml
# javaVersion=$(grep "<java.version>" pom.xml | grep -Eo '[0-9]{1,4}')

branch=$(git rev-parse --abbrev-ref HEAD)

echo "Application Name: $APP_NAME"
echo "Repository URL: $cdefenseURL"

# Sleep for a configured duration
sleep $SLEEP_DURATION

# Build number
BUILD_NUMBER=$(jq -r .build_detail.repository.tag < /bp/data/environment_build)
echo "$BUILD_NUMBER"

#curl -u $username:$password -O -L https://github.piramalfinance.com/raw/devops/build-scripts/main/jenkins/build-init.sh
# source build-init.sh

MAVEN_CLI_OPTS="--batch-mode --errors --fail-at-end --show-version -DinstallAtEnd=true -DdeployAtEnd=true"

if [[ "${branch}" == "hotfix-"* || "${branch}" == "hotfix_"* ]]; then
    echo "Skipping auth-client version check for Hotfix branch."
else
    auth_version=$(cat pom.xml | grep -A2 '<artifactId>auth-client</artifactId>' | grep '<version>' | awk -F'[<>]' '{print $3}')
    echo "$auth_version"
    if [[ "${auth_version}" == 3.0.* ]] || [ -z "${auth_version}" ]; then
        echo "Application is using correct auth-client version or not using auth-client dependency"
    else
        echo "Not using the latest updated version of auth-client. Hence Blocking the build."
        exit 1
    fi
fi

# Capture and save task status
TASK_STATUS=$?
saveTaskStatus "$TASK_STATUS" "$ACTIVITY_SUB_TASK_CODE"

# Exit with the captured task status
exit $TASK_STATUS




