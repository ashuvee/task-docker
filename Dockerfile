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
RUN apt-get update && apt-get install -y curl && \
    curl -u "${NEXUS_USERNAME}:${NEXUS_PASSWORD}" \
    -L -o /usr/local/tomcat/webapps/ROOT.war \
    "${NEXUS_URL}/service/rest/v1/search/assets/download?repository=${NEXUS_REPO}&group=${GROUP_ID}&name=${ARTIFACT_ID}&version=${VERSION}&maven.extension=war" && \
    apt-get remove -y curl && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Expose port
EXPOSE 8080
CMD ["catalina.sh", "run"]
