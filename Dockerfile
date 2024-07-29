FROM alpine

# Install necessary packages
RUN apk add --no-cache --upgrade bash
RUN apk add jq libxml2-utils maven git

# Copy the build script and add additional shell functions
COPY build.sh .
ADD BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

# Set environment variables
ENV SLEEP_DURATION 5s
ENV ACTIVITY_SUB_TASK_CODE BP-TAG-VALIDATOR-UPDATER
ENV VALIDATION_FAILURE_ACTION WARNING

# Make build.sh executable
RUN chmod +x build.sh

# Set the entry point to the build script
ENTRYPOINT [ "./build.sh" ]
