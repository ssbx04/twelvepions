FROM gradle:8.12-jdk21-alpine AS build
WORKDIR /build
COPY backend/ .
RUN ./gradlew bootJar --no-daemon -x test

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /build/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", \
  "-Xmx200m", \
  "-Xms64m", \
  "-XX:+UseSerialGC", \
  "-Dspring.jmx.enabled=false", \
  "-jar", "app.jar"]
