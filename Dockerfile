# Base image
FROM ubuntu:20.04

# Install necessary tools
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    jq \
    tzdata \
    && apt-get clean

RUN apt-get update && apt-get install -y git

# Set the timezone to Indian Standard Time (IST)
ENV TZ=Asia/Kolkata
ENV LANGUAGE

COPY build.sh .
ADD BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

ENV ACTIVITY_SUB_TASK_CODE DOCKER_FILE_CREATION

ENTRYPOINT [ "./build.sh" ]
