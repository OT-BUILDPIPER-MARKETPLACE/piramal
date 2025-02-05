#!/bin/bash

# Source additional shell functions and logging functions
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/getDataFile.sh

TASK_STATUS=0

export WORKSPACE=/bp/workspace
export CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"

if [ -d "$CODEBASE_LOCATION" ]; then
    logInfoMessage "I'll do processing at $CODEBASE_LOCATION"
else
    TASK_STATUS=1
    logErrorMessage "CODEBASE_LOCATION not defined or does not exist"
    exit 1
fi


sleep $SLEEP_DURATION

branch=`getGitBranch`
logInfoMessage "Branch Name -> ${branch}"

versioning() {

  if [[ "${branch}" = "master" ]] || [[ "${branch}" = "main" ]] ;

  then

     build_version=1.0.${BUILD_NUMBER}

  else

      build_version=0.0.${BUILD_NUMBER}-${BRANCH_NAME}

  fi

logInfoMessage "Updated tag is ${build_version} as the branch is ${branch}"
}

# Function to update the tag value in the JSON configuration
update_tag_value() {
    export json_file="/bp/data/environment_build"
    export new_tag="${build_version}"

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
# Call the function to generate build_version
versioning
# Call the function to update the tag value
update_tag_value

# Save the task status
saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
