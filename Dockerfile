    
FROM openjdk
MAINTAINER Islajd <islajdm@gmail.com>
COPY target/demo-*.jar target/demo.jar
ENTRYPOINT ["java", "-jar", "/demo.jar"]
EXPOSE 8080
