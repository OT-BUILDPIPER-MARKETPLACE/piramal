#!/bin/bash

# Load utility functions
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh


# Initialize variables
CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"
sleep $SLEEP_DURATION


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

BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Application Name: $APP_NAME"
echo "Repository URL: $cdefenseURL"

# Sleep for a configured duration
sleep $SLEEP_DURATION

# Build number
BUILD_NUMBER=$(jq -r .build_detail.repository.tag < /bp/data/environment_build)
echo "$BUILD_NUMBER"

#curl -u $username:$password -O -L https://github.piramalfinance.com/raw/devops/build-scripts/main/jenkins/build-init.sh
# source build-init.sh

ARTIFACTID=`mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout`

POM_RELEASE_VERSION=`mvn help:evaluate -Dexpression=project.version -q -DforceStdout | sed -e "s/-SNAPSHOT//" | sed -e"s/-\$BRANCH//"`

releasePlugin=`mvn help:evaluate -Dexpression=maven-release-plugin.version -q -DforceStdout`


if [ $BRANCH = "master" ] || [ $BRANCH = "main" ]
    then

        if [ $releasePlugin != 3.0.0-M1 ];
            then
                echo -e "Please update Maven Relese plugin to 3.0.0-M1 and Maven Deploy Plugin to 3.1.1"
                echo -e "Please verify the scm.connection for specific repo <scm.connection></scm.connection>"
            exit 1
        fi
        NEXT_RELEASE_VERSION=`echo ${POM_RELEASE_VERSION}| awk -F'.' '{print $1"."$2"."$3+1}'`
        mvn -s settings.xml versions:set -DnewVersion=${POM_RELEASE_VERSION}-SNAPSHOT
        echo -e "Release Version=[${POM_RELEASE_VERSION}], Next Release Snapshot Version=[${NEXT_RELEASE_VERSION}]"
        mvn -s settings.xml release:prepare release:perform -Dmaven.javadoc.skip=true -Darguments=-DskipTests -DscmCommentPrefix=[PRFDEVOPSB-4481] -Dtag=v${POM_RELEASE_VERSION} -DcheckModificationExcludeList=pom.xml --batch-mode --fail-at-end || { mvn release:rollback --batch-mode && false; }

    else

        BUILD_VERSION=${POM_RELEASE_VERSION}-$BRANCH

        mvn -s settings.xml versions:set -DnewVersion=${POM_RELEASE_VERSION}-$BRANCH
        mvn -s settings.xml clean install
        mvn -s settings.xml deploy:deploy-file -DgroupId=com.pchf.client -DartifactId=${ARTIFACTID} -Dversion=${BUILD_VERSION} -DpomFile=pom.xml -Dpackaging=jar -DrepositoryId=piramal-snapshots -Durl=https://nexus.piramalfinance.com/repository/piramal-snapshots/ -Dfile=$CODEBASE_LOCATION/target/${ARTIFACTID}-${BUILD_VERSION}.jar

      

fi

# Capture and save task status
TASK_STATUS=$?
saveTaskStatus "$TASK_STATUS" "$ACTIVITY_SUB_TASK_CODE"

# Exit with the captured task status
exit $TASK_STATUS

