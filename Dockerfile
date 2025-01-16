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

# Install cdefense
#RUN curl https://raw.githubusercontent.com/CloudDefenseAI/cd/master/latest/cd-latest-linux-x64.tar.gz > /tmp/cd-latest-linux-x64.tar.gz \
#    && tar -C /usr/local/bin -xzf /tmp/cd-latest-linux-x64.tar.gz \
#    && chmod +x /usr/local/bin/cdefense

# Set environment variables
ENV CDEFENSE_API_KEY=""
ENV LANGUAGE=""

COPY build.sh .
ADD BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

ENV ACTIVITY_SUB_TASK_CODE CODE_DEFENCE_SCAN

ENTRYPOINT [ "./build.sh" ]
