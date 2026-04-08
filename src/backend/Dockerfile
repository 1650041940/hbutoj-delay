FROM eclipse-temurin:8-jre-alpine

RUN apk add --no-cache curl

WORKDIR /hoj

COPY hoj-backend.jar /hoj/hoj-backend.jar

ENV JAVA_OPTS=""

EXPOSE 6688

CMD ["sh", "-c", "java $JAVA_OPTS -jar /hoj/hoj-backend.jar"]
