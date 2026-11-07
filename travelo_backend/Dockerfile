# syntax=docker/dockerfile:1

# ---------- Étape 1 : build (Maven + JDK) ----------
FROM maven:3.9-eclipse-temurin-23 AS build
WORKDIR /app

# Copier d'abord uniquement le pom.xml : la couche des dépendances reste en cache
# tant que le pom ne change pas
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---------- Étape 2 : exécution (JRE léger, utilisateur non-root) ----------
FROM eclipse-temurin:23-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

COPY --from=build --chown=spring:spring /app/target/*.jar app.jar

USER spring
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD nc -z localhost 8080 || exit 1

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75"
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
