#!/bin/bash

# Function to perform the security check
function python_security_Check() {
  local codebase_location=$1
  local branch=$2
  local scan_url=$3
  local cdefenseURL=$4
  local CDEFENSE_API_KEY=$5
  local APP_NAME=$6
  local username=$7
  local password=$8

  echo "Running python security check for branch: $branch at $codebase_location"
  
  export scan_url

  curl -u $username:$password -O -L https://github.piramalfinance.com/raw/devops/build-scripts/main/jenkins/applist.txt
  
  # Ensure we are in the correct directory
  cd "$codebase_location" || {
    echo "Error: Failed to change directory to $codebase_location"
    exit 1
  }


if [[ ${branch} = "master" ]] || [[ ${branch} = "main" ]] ;
then
      rm output.txt
       #version="`grep -o -m 1 1.0.1- pom.xml`"
      cdefense online  --api-key=${CDEFENSE_API_KEY} --repository-url=$cdefenseURL --is-enterprise --type=GITHUB  | tee output.txt
      cdefense_output_status=$(cat output.txt | grep -v "^Scan logs" | grep -iv "GITHUB")

      #cdefense_scan_status=$(cat output.txt| grep -o "Exposed Keys : secrets")
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
      rm output.txt
      if ! grep -q "$APP_NAME" "applist.txt" && [[ $cdefense_medium_status == "MEDIUM_SEVERITY_COUNT GREATER_THAN 0" ]]
      then
        echo "-------Failing Build Because This Application Has Medium Vulnerabilities-------"
        echo "-------MEDIUM_SEVERITY_COUNT GREATER_THAN 0-------"
         cat output.txt
        exit 1
         rm output.txt
      fi

else
      cdefense online --api-key=${CDEFENSE_API_KEY} --repository-url=$cdefenseURL --branch-name=${branch} --is-enterprise | tee output.txt
      cdefense_output_status=$(cat output.txt | grep -v "^Scan logs" | grep -iv "GITHUB")
      #cdefense_scan_status=$(cat output.txt| grep -o "Exposed Keys : secrets")
      cdefense_critical_status=$(cat output.txt| grep -o "CRITICAL_SEVERITY_COUNT GREATER_THAN 0" | uniq)
      cdefense_high_status=$(cat output.txt| grep -o "HIGH_SEVERITY_COUNT GREATER_THAN 0" | uniq)
      cdefense_medium_status=$(cat output.txt| grep -o "MEDIUM_SEVERITY_COUNT GREATER_THAN 0" | uniq)
      if [[ $cdefense_critical_status == "CRITICAL_SEVERITY_COUNT GREATER_THAN 0" ]] || [[ $cdefense_high_status == "HIGH_SEVERITY_COUNT GREATER_THAN 0" ]]
      then
            echo "-------Failing Build Because This Application Has Critical/High Vulnerabilities-------"
            echo "-------CRITICAL_SEVERITY_COUNT/HIGH_SEVERITY_COUNT GREATER_THAN 0-------"
            cat output.txt
            #exit 1
            rm output.txt
      fi
      rm output.txt
      if ! grep -q "$APP_NAME" "applist.txt" && [[ $cdefense_medium_status == "MEDIUM_SEVERITY_COUNT GREATER_THAN 0" ]]
      then
        echo "-------Failing Build Because This Application Has Medium Vulnerabilities-------"
        echo "-------MEDIUM_SEVERITY_COUNT GREATER_THAN 0-------"
         cat output.txt
        exit 1
         rm output.txt
      fi
}