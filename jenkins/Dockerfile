# Start from the official Jenkins LTS image
FROM jenkins/jenkins:lts

# Switch to the root user to install software
USER root

# Install Docker CLI, Maven, and Node.js so Jenkins can build and analyze
RUN apt-get update && \
    apt-get install -y --no-install-recommends docker.io maven nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add the 'jenkins' user to the 'docker' group to grant permissions
RUN usermod -aG docker jenkins

# Pre-install the Jenkins plugins we need for the pipeline
RUN jenkins-plugin-cli --plugins \
    git \
    workflow-aggregator \
    docker-workflow \
    sonar \
    nexus-artifact-uploader \
    credentials-binding \
    config-file-provider \
    pipeline-utility-steps

# Switch back to the standard 'jenkins' user
USER jenkins
