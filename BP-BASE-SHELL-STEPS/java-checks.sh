#!/bin/bash

cd "${CODEBASE_LOCATION:-/bp/workspace}"

# Retrieve Java version from pom.xml
javaVersion=$(grep "<java.version>" pom.xml | grep -Eo '[0-9]{1,4}')

# Function to perform the security check
function java_security_Check() {
  if [[ "$branch" =~ ^(master|main|release-.*)$ ]]; then
    if [[ "$javaVersion" != "17" ]]; then
      echo "Error: Service not migrated to Java 17/Spring Boot as per security guidelines."
      exit 1
    fi

    if [[ "$branch" =~ ^release-.*$ ]]; then
      cdefense online --api-key="${CDEFENSE_API_KEY}" --repository-url="$cdefenseURL" \
        --is-enterprise --type=GITHUB --branch-name="$branch" --scan-url="$SCAN_URL" | tee output.txt
    else
#      cdefense online --api-key="${CDEFENSE_API_KEY}" --repository-url="$cdefenseURL" \
#        --is-enterprise --type=GITHUB --scan-url="$SCAN_URL" | tee output.txt
       cdefense online --api-key=${CDEFENSE_API_KEY} --repository-url=$cdefenseURL| tee output.txt
    fi

        cat output.txt
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
 #   if [[ $medium_status && ! $(grep -q "$APP_NAME" "applist.txt") ]]; then
 #     echo "Error: Medium vulnerabilities found and application not exempt."
 #     cat "$output_file"
 #     rm -f "$output_file"
 #     exit 1
 #   fi

    rm -f "$output_file"
    echo "CloudDefense scan passed. Proceeding with build."
  fi

}
