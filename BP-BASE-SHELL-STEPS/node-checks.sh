#!/bin/bash

# Function to perform the security check
function node_security_Check() {
  local codebase_location=$1
  local branch=$2
  local scan_url=$3
  local cdefenseURL=$4
  local CDEFENSE_API_KEY=$5
  local APP_NAME=$6
  local username=$7
  local password=$8

cd "$codebase_location" || {
    echo "Error: Failed to change directory to $codebase_location"
    exit 1
  }

curl -u $username:$password -O -L https://github.piramalfinance.com/raw/devops/build-scripts/main/jenkins/applist.txt
#curl -u $username:$password -O -L https://github.piramalfinance.com/raw/devops/build-scripts/main/jenkins/build-init.sh
# source build-init.sh  
  
if [ "$branch" = "master" ] || [ "$branch" = "main" ]; then
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

