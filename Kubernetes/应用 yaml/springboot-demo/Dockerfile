FROM openjdk:8-jdk-alpine
WORKDIR /data
RUN addgroup -S -g 1200 spring && adduser -S -u 1200 -G spring spring
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
RUN chown -R spring.spring /data
USER spring:spring
ENTRYPOINT ["java","-jar","/data/app.jar"]
