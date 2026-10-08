FROM tomcat:9.0-jdk21-temurin

RUN rm -rf /usr/local/tomcat/webapps/*

COPY target/addressbook.war /usr/local/tomcat/webapps/addressbook.war

EXPOSE 8080
