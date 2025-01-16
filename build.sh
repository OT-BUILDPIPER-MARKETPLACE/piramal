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

# Extract the username
username=$(grep 'url' .git/config | grep -oP '(?<=://)[^:]*')

# Extract the password/token
password=$(grep 'url' .git/config | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')


# Extract repository URL from git configuration
cdefenseURL=$(grep -oP '(?<=url = ).*' .git/config)
if [ -z "$cdefenseURL" ]; then
  logErrorMessage "Failed to extract repository URL from .git/config"
  exit 1
fi

# Derive the application name from the repository URL
APP_NAME=$(basename "$cdefenseURL" .git)

if [ -z "$APP_NAME" ]; then
  logErrorMessage "Failed to derive application name from repository URL"
  exit 1
fi


branch=$(git rev-parse --abbrev-ref HEAD)

echo "Application Name: $APP_NAME"

echo "Repository URL: $cdefenseURL"

# Sleep for a configured duration
sleep $SLEEP_DURATION

service_name=$APP_NAME
echo "service_name: $APP_NAME"

# Build number
BUILD_NUMBER=$(jq -r .build_detail.repository.tag < /bp/data/environment_build)
echo "$BUILD_NUMBER"

  if [[ "${branch}" = "master" ]] || [[ "${branch}" = "main" ]] ;
  then
     build_version=1.0.${BUILD_NUMBER}
  else

      build_version=0.0.${BUILD_NUMBER}-${branch}
  fi

if [[ "${branch}" = "master" ]] || [[ "${branch}" = "main" ]] || [[ "${branch}" =~ ^release-.*$ ]] || [[ "${branch}" =~ ^hotfix_.*$ ]];
    then
      git tag v${build_version}
      git push origin v${build_version}
    fi

# Capture and save task status
TASK_STATUS=$?
saveTaskStatus "$TASK_STATUS" "$ACTIVITY_SUB_TASK_CODE"

# Exit with the captured task status
exit $TASK_STATUS




