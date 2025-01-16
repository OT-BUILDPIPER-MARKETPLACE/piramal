#!/bin/bash
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh

function createEntrypointDockerFileJava()
{
    
    local encryption_enabled=$1

  if [ $encryption_enabled = "mongo-encryption-util" ] ;
    then
    echo -e " Mongo encryption Enabled"
    echo "#!/bin/bash
          /usr/bin/mongocryptd &
          java  -javaagent:/app/opentelemetry-1.0.1.jar -Dotel.resource.attributes=service.name=${APP_NAME} \${JAVA_OPTS} -Dotel.propagators=b3multi -Dotel.traces.exporter=zipkin  -Dotel.exporter.zipkin.endpoint=http://otel-collector.devopsnow.svc.cluster.local:9411  -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar /app/service.jar " > entrypoint.sh
   
    echo "FROM nexus.piramalfinance.com:8082/repository/piramal-docker/java-mongocryptd:java17
      WORKDIR /app
      COPY entrypoint.sh /app/
      COPY target/*.jar /app/service.jar
      ADD https://nexus.piramalfinance.com/repository/piramal-releases/com/pchf/opentelemetry/1.24.0/opentelemetry-1.24.0.jar /app
      RUN mv opentelemetry-1.24.0.jar opentelemetry-1.0.1.jar
      RUN chmod +x entrypoint.sh
      ENTRYPOINT [\"./entrypoint.sh\"] " > Dockerfile

  else
    echo "#!/bin/bash
          java  -javaagent:/app/opentelemetry-1.0.1.jar -Dotel.resource.attributes=service.name=${APP_NAME} \${JAVA_OPTS} -Dotel.propagators=b3multi -Dotel.traces.exporter=zipkin  -Dotel.exporter.zipkin.endpoint=http://otel-collector.devopsnow.svc.cluster.local:9411  -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar /app/service.jar " > entrypoint.sh
          echo "nexus.piramalfinance.com:8082/repository/piramal-docker/prf-java:java17
                  WORKDIR /app
                  COPY target/*.jar /app/service.jar
                  ADD https://nexus.piramalfinance.com/repository/piramal-releases/com/pchf/opentelemetry/1.24.0/opentelemetry-1.24.0.jar /app
                  RUN mv opentelemetry-1.24.0.jar opentelemetry-1.0.1.jar
                  COPY entrypoint.sh /app/
                  RUN chmod +x entrypoint.sh
                  ENTRYPOINT [\"./entrypoint.sh\"] " > Dockerfile
  fi


}


function createEntrypointDockerFileNode()
{
    local service_name=$1
    if [[ $service_name == "apf-web" || $service_name == "partner-central-web" || $service_name == "insurance-web" || $service_name == "incentive-management-web" || $service_name == "direct-assignment-web" || $service_name == "prospect-web" || $service_name == "pchfweb" || $service_name == "esign-mf-web" || $service_name == "review-mfe-web" || $service_name == "customer-satisfaction-survey-web" || $service_name == "pq-portal-web" || $service_name == "ai-web" || $service_name == "chatbot-web" || $service_name == "khata-web" || $service_name == "platform-tools-web" || $service_name == "shakti-web" || $service_name == "telesales-web" || $service_name == "customer-account-web" || $service_name == "credit-report-web" || $service_name == "communication-template-management-web" || $service_name == "offer-central-web" || $service_name == "tele-collection-web" || $service_name == "credit-central-web" || $service_name == "sx-engagement-mf-web" || $service_name == "tatkal-web" || $service_name == "kyc-web" || $service_name == "policy-designer-web" || $service_name == "policy-manager-web" || $service_name == "url-redirect-web" || $service_name == "pd-platform-web" || $service_name == "sc-customer-web" || $service_name == "vendor-management-web" || $service_name == "collections-web" || $service_name == "login-mfe-web" || $service_name == "bank-verification-mf-web" ]];
    then
            echo "FROM nexus.piramalfinance.com:8082/repository/piramal-docker/node-18.17.0-alpine
            WORKDIR /app
            COPY ./ /app/
            ENV NODE_OPTIONS=\"--max-old-space-size=4096\"
            RUN yarn install --network-timeout 1000000 \
            && yarn build"> Dockerfile
    else
            echo "FROM nexus.piramalfinance.com:8082/repository/piramal-docker/node-18.14.0-alpine
            WORKDIR /app
            COPY ./ /app/
            ENV NODE_OPTIONS=\"--max-old-space-size=4096\"
            RUN yarn install --network-timeout 1000000 \
            && yarn build"> Dockerfile
    fi
   

}

CODEBASE_LOCATION="${WORKSPACE}"/"${CODEBASE_DIR}"
logInfoMessage "I'll do processing at [$CODEBASE_LOCATION]"
sleep  $SLEEP_DURATION
cd  "${CODEBASE_LOCATION}"

case $LANGUAGE in
  java)
   encryption_enabled=`grep -o "mongo-encryption-util" pom.xml`
   createEntrypointDockerFileJava  $encryption_enabled 
   TASK_STATUS=$?
   saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
    ;;
  node)
   service_name=$(grep -oP '(?<=url = ).*' .git/config |awk -F'/' '{print $NF}' |  sed 's/.git$//')
   echo "creating docker file of the service : $service_name"
   createEntrypointDockerFileNode $service_name
   TASK_STATUS=$?
   saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
    ;;
    
  python)
    # Commands to execute if pattern2 matches
    ;;  
  *)
     echo "please provide valid value to LANGUAGE variable .valid values are java,python and node"
    ;;
esac
