#!/bin/bash

# Source additional shell functions and logging functions
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh

# Define codebase location based on environment variables
CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"
logInfoMessage "I'll do processing at [$CODEBASE_LOCATION]"

# Wait for a specified duration
sleep $SLEEP_DURATION

# Change directory to the codebase location
cd "${CODEBASE_LOCATION}" || { logErrorMessage "Failed to change directory to $CODEBASE_LOCATION"; exit 1; }

# Function to get the version from the pom.xml file
get_version_from_pom() {
    version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" pom.xml)
    echo "$version"
}

# Function to check if a tag exists in the git repo
tag_exists() {
    git fetch --tags
    if git rev-parse "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to increment the version
increment_version() {
    local version=$1
    local IFS='.'
    local parts=($version)
    local last_index=$((${#parts[@]} - 1))
    parts[$last_index]=$((${parts[$last_index]} + 1))
    echo "${parts[*]}" | tr ' ' '.'
}

# Main script
main() {
    current_version=$(get_version_from_pom)

    if tag_exists "$current_version"; then
        new_version=$(increment_version "$current_version")
        mvn versions:set -DnewVersion="$new_version" > /dev/null 2>&1
        mvn versions:commit > /dev/null 2>&1
        git add pom.xml
        git commit -m "Update version to $new_version"
        git tag "$new_version"
        echo "Version updated to $new_version and tagged locally."
    else
        git tag "$current_version"
        echo "Tag $current_version created locally."
    fi
}

# Execute the main function
main "$@"

# Additional processing and condition check
if [condition]; then
    logErrorMessage "Done the required operation"
else
    TASK_STATUS=1
    logErrorMessage "Target server not provided please check"
fi

# Save the task status
saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
