FROM alpine

# Install necessary packages
RUN apk add --no-cache --upgrade bash jq libxml2-utils maven git moreutils

# Copy the build script and add additional shell functions
COPY build.sh .
ADD BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

# Set environment variables
ENV SLEEP_DURATION 5s
ENV ACTIVITY_SUB_TASK_CODE BP-IMAGE_TAG-GOVERNER
ENV VALIDATION_FAILURE_ACTION ""

# Make build.sh executable
RUN chmod +x build.sh

# Set the entry point to the build script
ENTRYPOINT [ "./build.sh" ]
