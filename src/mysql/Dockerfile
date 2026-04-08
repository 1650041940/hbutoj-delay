FROM mysql:8

ENV TZ=Asia/Shanghai

# Initialize databases on first container start.
# Note: mysql official image will run all *.sql under /docker-entrypoint-initdb.d
COPY 00-create-databases.sql /docker-entrypoint-initdb.d/00-create-databases.sql
COPY 10-hoj.sql /docker-entrypoint-initdb.d/10-hoj.sql
COPY 20-nacos.sql /docker-entrypoint-initdb.d/20-nacos.sql
