FROM tomcat:9-jre21
LABEL maintainer="admin@example.com"
LABEL application="sample-webapp"

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file from build context
COPY sample-webapp.war /usr/local/tomcat/webapps/ROOT.war

# Expose port
EXPOSE 8080
CMD ["catalina.sh", "run"]
