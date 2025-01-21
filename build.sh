#!/bin/bash

# Load utility functions
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/cdefense.sh
source /opt/buildpiper/shell-functions/java-checks.sh
source /opt/buildpiper/shell-functions/node-checks.sh
source /opt/buildpiper/shell-functions/python-checks.sh

# Default CloudDefense installation URL (can be overridden via environment variable)
CDEFENSE_INSTALL_URL=${CDEFENSE_INSTALL_URL:-"https://raw.githubusercontent.com/CloudDefenseAI/cd/master/latest/cd-latest-linux-x64.tar.gz"}


# Install CloudDefense if necessary
install_cdefense "$CDEFENSE_INSTALL_URL"

# Initialize variables
CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"
SCAN_URL=${SCAN_URL:-"https://clouddefense.piramalfinance.com/"} # Default if not provided
SLEEP_DURATION=${SLEEP_DURATION:-0}

logInfoMessage "Starting build process for code at ${CODEBASE_LOCATION}"

# Output the scan URL
echo "Using Scan URL: $SCAN_URL"

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

# Retrieve Java version from pom.xml
# javaVersion=$(grep "<java.version>" pom.xml | grep -Eo '[0-9]{1,4}')

branch=$(git rev-parse --abbrev-ref HEAD)

echo "Application Name: $APP_NAME"

echo "Repository URL: $cdefenseURL"

# Sleep for a configured duration
sleep $SLEEP_DURATION


# Execute the function with language specific
case $LANGUAGE in
  java)
    java_security_Check "$CODEBASE_LOCATION" "$branch" "$SCAN_URL" "$cdefenseURL" "$CDEFENSE_API_KEY"  "$APP_NAME" "$username" "$password"
    ;;
  node)
    node_security_Check "$CODEBASE_LOCATION" "$branch" "$SCAN_URL" "$cdefenseURL" "$CDEFENSE_API_KEY" "$APP_NAME" "$username" "$password"
    ;;
    
  python)
    python_security_Check "$CODEBASE_LOCATION" "$branch" "$SCAN_URL" "$cdefenseURL" "$CDEFENSE_API_KEY" "$APP_NAME" "$username" "$password"
    ;;  
  *)
     echo "please provide valid value to LANGUAGE variable .valid values are java,python and node"
    ;;
esac

# Capture and save task status
TASK_STATUS=$?
saveTaskStatus "$TASK_STATUS" "$ACTIVITY_SUB_TASK_CODE"

# Exit with the captured task status
exit $TASK_STATUS




