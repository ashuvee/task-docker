FROM tomcat:9-jre21
LABEL maintainer="admin@example.com"
LABEL application="sample-webapp"

# Build arguments for Nexus artifact retrieval
ARG NEXUS_URL=http://136.112.216.68:8081
ARG NEXUS_REPO=maven-snapshots
ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD
ARG GROUP_ID=com.example
ARG ARTIFACT_ID=sample-webapp
ARG VERSION=1.0-SNAPSHOT


SHELL ["/bin/bash", "-c"]
# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Install wget and download artifact from Nexus with authentication
RUN apt-get update && apt-get install -y wget && \
    wget --no-check-certificate \
    --user="${NEXUS_USERNAME}" \
    --password="${NEXUS_PASSWORD}" \
    -O /usr/local/tomcat/webapps/ROOT.war \
    "${NEXUS_URL}/repository/${NEXUS_REPO}/${GROUP_ID//.//}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.war" && \
    apt-get remove -y wget && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Expose port
EXPOSE 8080
CMD ["catalina.sh", "run"]
