FROM eclipse-temurin:8-jre-alpine

WORKDIR /judge

# The build script copies hoj-judgeServer-*.jar into this directory.
COPY hoj-judgeServer-*.jar /judge/hoj-judgeServer.jar

ENV JAVA_OPTS=""

EXPOSE 8088

CMD ["sh", "-c", "java $JAVA_OPTS -jar /judge/hoj-judgeServer.jar"]
