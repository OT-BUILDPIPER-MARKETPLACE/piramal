#!/bin/bash

# Function to perform the security check
function java_security_Check() {
  local codebase_location=$1
  local branch=$2
  local scan_url=$3
  local cdefenseURL=$4
  local CDEFENSE_API_KEY=$5
  local APP_NAME=$6
  local username=$7
  local password=$8

  echo "Running Java security check for branch: $branch at $codebase_location"
  
  export scan_url


  
  # Ensure we are in the correct directory
  cd "$codebase_location" || {
    echo "Error: Failed to change directory to $codebase_location"
    exit 1
  }

  # Retrieve Java version from pom.xml
  local java_version=$(grep "<java.version>" pom.xml | grep -Eo '[0-9]{1,4}')
  
  curl -u $username:$password -O -L https://github.piramalfinance.com/raw/devops/build-scripts/main/jenkins/applist.txt
  #curl -u $username:$password -O -L https://github.piramalfinance.com/raw/devops/build-scripts/main/jenkins/build-init.sh
  # source build-init.sh

  if [[ "$branch" =~ ^(master|main|release-.*)$ ]]; then
    if [[ "$javaVersion" != "17" ]]; then
      echo "Error: Service not migrated to Java 17/Spring Boot as per security guidelines."
      exit 1
    fi

      if [[ "${branch}" =~ ^release-.*$ ]] ; then
      cdefense online  --api-key=${CDEFENSE_API_KEY} --repository-url=$cdefenseURL --is-enterprise --type=GITHUB --branch-name=${branch} | tee output.txt
      else
      cdefense online  --api-key=${CDEFENSE_API_KEY} --repository-url=$cdefenseURL --is-enterprise --type=GITHUB  | tee output.txt
      fi

        cdefense_output_status=$(cat output.txt | grep -v "^Scan logs" | grep -iv "GITHUB")

    if [[ -z "$cdefense_output_status" ]];
    then
    echo "Issue identified during Clouddefense Scan, Hence Exiting the Build. Please retry the build."
    exit 1
    else
    echo "Continuing the Build for CloudDefense"
    fi

      cdefense_critical_status=$(cat output.txt| grep -o "CRITICAL_SEVERITY_COUNT GREATER_THAN 0" | uniq)
      cdefense_high_status=$(cat output.txt| grep -o "HIGH_SEVERITY_COUNT GREATER_THAN 0" | uniq)
      cdefense_medium_status=$(cat output.txt| grep -o "MEDIUM_SEVERITY_COUNT GREATER_THAN 0" | uniq)
      if [[ $cdefense_critical_status == "CRITICAL_SEVERITY_COUNT GREATER_THAN 0" ]] || [[ $cdefense_high_status == "HIGH_SEVERITY_COUNT GREATER_THAN 0" ]]
      then
            echo "-------Failing Build Because This Application Has Critical/High Vulnerabilities-------"
            echo "-------CRITICAL_SEVERITY_COUNT/HIGH_SEVERITY_COUNT GREATER_THAN 0-------"
            cat output.txt
            exit 1
            rm output.txt
      fi
      if [[ $medium_status && ! $(grep -q "$APP_NAME" "applist.txt") ]]; then
            echo "Error: Medium vulnerabilities found and application not exempt."
            cat "$output_file"
            rm -f "$output_file"
            exit 1
      fi

    rm -f "$output_file"
    echo "CloudDefense scan passed. Proceeding with build."
  fi

}
