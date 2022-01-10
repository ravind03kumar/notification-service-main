#instructions to convert our spring boot application to Docker image
FROM openjdk:16-alpine3.13 as base

#RUN addgroup -S spring-boot && adduser -S spring-boot -G spring-boot

#USER spring-boot
#setup the working directory
WORKDIR /app

#Copy the build scripts (maven and pom.xml)
COPY mvnw .
COPY pom.xml .
COPY .mvn .mvn

#RUN the maven dependency plugin
RUN chmod +x ./mvnw
RUN ./mvnw -B dependency:go-offline

COPY src ./src

FROM base as test
CMD ["./mvnw", "test"]

FROM base as development
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=dev"]

FROM base as build
#RUN --mount=type=cache,target=/root/.m2/repository
RUN ./mvnw package && mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)


FROM openjdk:11.0.4-jre-slim-buster as production

ARG DEPENDENCY=/app/target/dependency

# For troubleshooting
RUN apt-get update && apt-get install -y curl

# Copy the dependency application file from builder stage artifact
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

EXPOSE 8222

ENTRYPOINT ["java", "-cp", "app:app/lib/*", "com.synechron.notificationservice.NotificationServiceApplication"]





