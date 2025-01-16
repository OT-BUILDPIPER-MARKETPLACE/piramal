#!/bin/bash

cd "${CODEBASE_LOCATION:-/bp/workspace}"

# Function to perform the security check
function node_security_Check() {
if [ "$branch" = "master" ] || [ "$branch" = "main" ]; then
    new_version="1.0.$BUILD_NUMBER"
    echo "version=$new_version" > version.txt

    cdefense online --api-key="${CDEFENSE_API_KEY}" --repository-url="$cdefenseURL" --is-enterprise --type=GITHUB | tee output.txt
    cdefense_output_status=$(grep -vE "^Scan logs|GITHUB" output.txt)

    if [ -z "$cdefense_output_status" ]; then
        echo "Issue identified during CloudDefense Scan. Exiting the build. Please retry."
        exit 1
    else
        echo "Continuing the Build for CloudDefense"
    fi

    cdefense_critical_status=$(grep -o "CRITICAL_SEVERITY_COUNT GREATER_THAN 0" output.txt | uniq)
    cdefense_high_status=$(grep -o "HIGH_SEVERITY_COUNT GREATER_THAN 0" output.txt | uniq)
    cdefense_medium_status=$(grep -o "MEDIUM_SEVERITY_COUNT GREATER_THAN 0" output.txt | uniq)

    if [[ "$cdefense_critical_status" == "CRITICAL_SEVERITY_COUNT GREATER_THAN 0" ]] || \
       [[ "$cdefense_high_status" == "HIGH_SEVERITY_COUNT GREATER_THAN 0" ]]; then
        echo "Failing Build: Critical/High vulnerabilities detected!"
        cat output.txt
        rm output.txt
        exit 1
    fi

    if ! grep -q "$APP_NAME" "applist.txt" && [[ "$cdefense_medium_status" == "MEDIUM_SEVERITY_COUNT GREATER_THAN 0" ]]; then
        echo "Failing Build: Medium vulnerabilities detected!"
        cat output.txt
        rm output.txt
        exit 1
    fi

    rm output.txt
else
    new_version="0.0.$BUILD_NUMBER-${GIT_BRANCH}"

    cdefense online --api-key="${CDEFENSE_API_KEY}" --repository-url="$cdefenseURL" --is-enterprise --type=GITHUB | tee output.txt
    cdefense_output_status=$(grep -vE "^Scan logs|GITHUB" output.txt)

    if [ -z "$cdefense_output_status" ]; then
        echo "Issue identified during CloudDefense Scan. Exiting the build. Please retry."
        exit 1
    else
        echo "Continuing the Build for CloudDefense"
    fi

    cdefense_critical_status=$(grep -o "CRITICAL_SEVERITY_COUNT GREATER_THAN 0" output.txt | uniq)
    cdefense_high_status=$(grep -o "HIGH_SEVERITY_COUNT GREATER_THAN 0" output.txt | uniq)
    cdefense_medium_status=$(grep -o "MEDIUM_SEVERITY_COUNT GREATER_THAN 0" output.txt | uniq)

    if [[ "$cdefense_critical_status" == "CRITICAL_SEVERITY_COUNT GREATER_THAN 0" ]] || \
       [[ "$cdefense_high_status" == "HIGH_SEVERITY_COUNT GREATER_THAN 0" ]]; then
        echo "Failing Build: Critical/High vulnerabilities detected!"
        cat output.txt
        rm output.txt
        exit 1
    fi

    if ! grep -q "$APP_NAME" "applist.txt" && [[ "$cdefense_medium_status" == "MEDIUM_SEVERITY_COUNT GREATER_THAN 0" ]]; then
        echo "Failing Build: Medium vulnerabilities detected!"
        cat output.txt
        rm output.txt
        exit 1
    fi

    rm output.txt
fi
}

