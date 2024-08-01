#!/bin/bash

# Source additional shell functions and logging functions
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh

TASK_STATUS=0

# Define codebase location based on environment variables
export WORKSPACE=/bp/workspace
export CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"

# Verify CODEBASE_LOCATION
if [ -d "$CODEBASE_LOCATION" ]; then
    logInfoMessage "I'll do processing at $CODEBASE_LOCATION"
else
    TASK_STATUS=1
    logErrorMessage "CODEBASE_LOCATION not defined or does not exist"
    exit 1
fi

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

# Function to update the tag value in the JSON configuration
update_tag_value() {
    export json_file="/bp/data/environment_build"
    export new_tag="$1"

    if [ -z "$new_tag" ]; then
        logErrorMessage "Error: New tag value is required."
        return 1
    fi

    # Check if jq is installed
    if ! command -v jq >/dev/null 2>&1; then
        logErrorMessage "jq is required but it's not installed."
        return 1
    fi

    # Use jq to update the tag value directly in the file
    jq --arg tag "$new_tag" '.build_detail.repository.tag = $tag' "$json_file" | sponge "$json_file"

    # Log mechanism for renaming the file
    if [ $? -eq 0 ]; then
        logInfoMessage "Tag updated to $new_tag successfully."
    else
        logErrorMessage "Failed to update tag."
        return 1
    fi
}

# Main script
main() {
    export current_version=$(get_version_from_pom)

    if [ -z "$current_version" ]; then
        TASK_STATUS=1
        logErrorMessage "Failed to get current version from pom.xml"
        exit 1
    else
        logInfoMessage "Current version is $current_version"
    fi

    if tag_exists "$current_version"; then
        export new_version=$(increment_version "$current_version")

        if [ $? -eq 0 ]; then
            logInfoMessage "New version is $new_version"
        else
            TASK_STATUS=1
            logErrorMessage "Failed to increment version"
            exit 1
        fi

        mvn versions:set -DnewVersion="$new_version" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            logInfoMessage "Maven version set to $new_version"
        else
            TASK_STATUS=1
            logErrorMessage "Failed to set new version with Maven"
            exit 1
        fi

        mvn versions:commit > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            logInfoMessage "Maven versions committed"
        else
            TASK_STATUS=1
            logErrorMessage "Failed to commit new version with Maven"
            exit 1
        fi

        # Update the tag in JSON configuration
        update_tag_value "$new_version"
        if [ $? -eq 0 ]; then
            logInfoMessage "Updated tag in JSON configuration to $new_version"
        else
            TASK_STATUS=1
            logErrorMessage "Failed to update tag in JSON configuration"
            exit 1
        fi
    else
        # Update the tag in JSON configuration
        update_tag_value "$current_version"
        if [ $? -eq 0 ]; then
            logInfoMessage "Updated tag in JSON configuration to $current_version"
        else
            TASK_STATUS=1
            logErrorMessage "Failed to update tag in JSON configuration"
            exit 1
        fi
    fi
}

# Execute the main function
main "$@"

# Save the task status
saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}