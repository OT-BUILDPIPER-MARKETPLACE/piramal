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
cdefenseURL=$(grep -oP '(?<=url = ).*' .git/config | sed -E 's#(https?://)[^:@]+(:[^@]*)?@#\1#')
if [ -z "$cdefenseURL" ]; then
  logErrorMessage "Failed to extract repository URL from .git/config"
  exit 1
fi

# Derive the application name from the repository URL
APP_NAME=$CODEBASE_DIR

if [ -z "$APP_NAME" ]; then
  logErrorMessage "Failed to derive application name from repository URL"
  exit 1
fi


GIT_BRANCH=$getGitBranch

echo "Application Name: $APP_NAME"

echo "Repository URL: $cdefenseURL"

# Sleep for a configured duration
sleep $SLEEP_DURATION

service_name=$APP_NAME
echo "service_name: $APP_NAME"

# Build number
BUILD_NUMBER=$(jq -r .build_detail.repository.tag < /bp/data/environment_build)
echo "$BUILD_NUMBER"

if [ "$GIT_BRANCH" = "master" ] || [ "$GIT_BRANCH" = "main" ]; then
  new_version="1.0.$BUILD_NUMBER"
else
  new_version="0.0.$BUILD_NUMBER-$GIT_BRANCH"
fi

sed -i "s/$service_name/$service_name-$new_version/g" next.config.js
        cat next.config.js

        echo "//r.privjs.com/:_authToken=$NPM_AUTH_TOKEN
    @module-federation:registry=https://r.privjs.com/"> .npmrc

    if grep -q "gitlab" "yarn.lock"; then
    echo "@services:registry=https://gitlab.piramalfinance.com/api/v4/packages/npm/
         //gitlab.piramalfinance.com/api/v4/packages/npm/:_authToken=$NPM_AUTH_TOKEN
         //gitlab.piramalfinance.com/api/v4/projects/564/packages/npm/:_authToken=$NPM_AUTH_TOKEN
         " >> .npmrc
    else
    echo "@services:registry=https://github.piramalfinance.com/_registry/npm/
    //github.piramalfinance.com/_registry/npm/:_authToken=$GITHUB_NPM_READ_TOKEN" >> .npmrc
    fi

echo -e "OTEL_AUTH_SECRET='$OTEL_AUTH_SECRET'
OTEL_ENDPOINT='https://otel-traces.piramalfinance.com/api/v2/spans'">> .env

# Capture and save task status
TASK_STATUS=$?
saveTaskStatus "$TASK_STATUS" "$ACTIVITY_SUB_TASK_CODE"

# Exit with the captured task status
exit $TASK_STATUS




