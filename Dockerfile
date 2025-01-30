# Base image with Maven and JDK
FROM maven:3.8.8-eclipse-temurin-17 as builder

# Copy your scripts and other files
COPY build.sh .
ADD BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

# Set the timezone to Indian Standard Time (IST)
ENV TZ=Asia/Kolkata

# Optional: Install additional tools if needed
RUN apt-get update && apt-get install -y jq ssh

# Environment variable
ENV ACTIVITY_SUB_TASK_CODE  DEPENDENCY_JAR_CHECK_FOR_MVN

ENTRYPOINT ["./build.sh"]

