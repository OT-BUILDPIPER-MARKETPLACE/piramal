#!/bin/bash

# Source additional shell functions and logging functions
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh

# Define codebase location based on environment variables
export CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"
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

# Function to update the tag value in the JSON configuration
update_tag_value() {
    export json_file="/bp/data/environment_build"
    export new_tag="$1"

    if [ -z "$new_tag" ]; then
        logErrorMessage "Error: New tag value is required."
        return 1
    fi

    # Check if jq and sponge are installed
    if ! command -v jq >/dev/null 2>&1; then
        logErrorMessage "jq is required but it's not installed."
        return 1
    fi
    if ! command -v sponge >/dev/null 2>&1; then
        logErrorMessage "sponge is required but it's not installed."
        return 1
    fi

    # Use jq to update the tag value directly in the file
    jq --arg tag "$new_tag" '.build_detail.repository.tag = $tag' "$json_file" | sponge "$json_file"

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

    if tag_exists "$current_version"; then
        export new_version=$(increment_version "$current_version")
        mvn versions:set -DnewVersion="$new_version" > /dev/null 2>&1
        mvn versions:commit > /dev/null 2>&1
        git add pom.xml
        git commit -m "Update version to $new_version"
        git tag "$new_version"
        logInfoMessage "Version updated to $new_version and tagged locally."

        # Update the tag in JSON configuration
        update_tag_value "$new_version"
    else
        git tag "$current_version"
        logInfoMessage "Tag $current_version created locally."

        # Update the tag in JSON configuration
        update_tag_value "$current_version"
    fi
}

# Execute the main function
main "$@"

# Show the value for each environment variable used in the script
logInfoMessage "Printing environment variables used in the script:"
logInfoMessage "WORKSPACE: ${WORKSPACE:-unset}"
logInfoMessage "CODEBASE_DIR: ${CODEBASE_DIR:-unset}"
logInfoMessage "SLEEP_DURATION: ${SLEEP_DURATION:-unset}"
logInfoMessage "TASK_STATUS: ${TASK_STATUS:-unset}"
logInfoMessage "ACTIVITY_SUB_TASK_CODE: ${ACTIVITY_SUB_TASK_CODE:-unset}"
logInfoMessage "current_version: ${current_version:-unset}"
logInfoMessage "new_version: ${new_version:-unset}"
logInfoMessage "new_tag: ${new_tag:-unset}"
logInfoMessage "json_file: ${json_file:-unset}"
logInfoMessage "last_index: ${last_index:-unset}"
logInfoMessage "parts: ${parts[*]:-unset}"

# Additional processing and condition check
if [condition]; then
    logErrorMessage "Done the required operation"
else
    export TASK_STATUS=1
    logErrorMessage "Target server not provided please check"
fi

# Save the task status
saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}

# Print the updated JSON file
cat /bp/data/environment_build | jq
