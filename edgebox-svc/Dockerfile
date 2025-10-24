FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:21-jre
ENV APP_HOME=/opt/edgebox
RUN useradd -r -u 1000 edgebox && mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}
COPY --from=build /workspace/target/edgebox-svc-*.jar app.jar
RUN chown -R edgebox:edgebox ${APP_HOME}
USER edgebox
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
