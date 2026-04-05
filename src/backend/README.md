## 前言

当前文件夹为打包后端镜像（`hbutoj-backend` 服务所用镜像）的构建上下文文件。

你需要先在源码仓库中打包 DataBackup（SpringBoot 模块）生成 jar，然后把 jar 放到当前目录，再执行构建。

```shell
docker build -t hbutoj-backend .
```

或者直接下载本项目，进入到当前文件夹执行打包命令

```shell
git clone <YOUR_DEPLOY_REPO_URL> && cd <YOUR_DEPLOY_REPO_DIR>/src/backend

docker build -t hbutoj-backend .
```



**项目依赖于 hbutoj-redis、hbutoj-nacos、hbutoj-mysql 等服务成功启动，以及根据前面三个服务的配置修改环境参数才可正常启动**

docker-compose 启动

```yaml
version: "3"
services:
  hbutoj-backend:
#    image: ghcr.io/1650041940/hbutoj_backend:latest
	image: hbutoj-backend
    container_name: hbutoj-backend
    restart: always
    depends_on:
      - hbutoj-redis
      - hbutoj-mysql
      - hbutoj-nacos
    volumes:
      - ./hbutoj/file:/hoj/file
      - ./hbutoj/testcase:/hoj/testcase
      - ./hbutoj/log/backend:/hoj/log/backend
    environment:
      - TZ=Asia/Shanghai
      - BACKEND_SERVER_PORT=6688 # backend服务端口号
      - NACOS_URL=172.20.0.4:8848 # hbutoj-nacos 的 url
      - NACOS_USERNAME=root # nacos的管理员账号
      - NACOS_PASSWORD=hoj123456 # nacos的管理员密码
      - JWT_TOKEN_SECRET=default # 加密秘钥 默认则生成32位随机密钥
      - JWT_TOKEN_EXPIRE=86400 # token过期时间默认为24小时 86400s
      - JWT_TOKEN_FRESH_EXPIRE=43200 # token默认12小时可自动刷新
      - JUDGE_TOKEN=default # 调用判题服务器的token 默认则生成32位随机密钥
      - MYSQL_HOST=172.20.0.3 # hbutoj-mysql 的 host
      - MYSQL_PUBLIC_HOST=172.20.0.3 # 如果判题服务是分布式，请提供当前mysql所在服务器的公网ip
      - MYSQL_PORT=3306 # hbutoj-mysql 端口号
      - MYSQL_DATABASE_NAME=hoj # 改动需要修改 db 镜像,默认为 hoj
      - MYSQL_USERNAME=root 
      - MYSQL_ROOT_PASSWORD=hoj123456 # mysql 的 root 账号密码
      - EMAIL_SERVER_HOST=smtp.qq.com # 请使用邮件服务的域名或ip
      - EMAIL_SERVER_PORT=465 # 请使用邮件服务的端口号
      - EMAIL_USERNMAE=-your_email_username # 请使用对应邮箱账号
      - EMAIL_PASSWORD=-your_email_password # 请使用对应邮箱密码
      - REDIS_HOST=172.20.0.2 # hbutoj-redis 的 host
      - REDIS_PORT=6379 # hbutoj-redis 的 port
      - REDIS_PASSWORD=hoj123456 # redis 的密码
      - OPEN_REMOTE_JUDGE=true # 是否开启对hdu和codeforces的虚拟判题
      # 开启虚拟判题请提供对应oj的账号密码 格式为 
      # username1,username2,...
      # password1,password2,...
      - HDU_ACCOUNT_USERNAME_LIST=
      - HDU_ACCOUNT_PASSWORD_LIST=
      - CF_ACCOUNT_USERNAME_LIST=
      - CF_ACCOUNT_USERNAME_LIST=
    ports:
      - "6688:6688"
    networks:
      hbutoj-network:
        ipv4_address: 172.20.0.5
        
  hbutoj-redis:
    image: redis:5.0.9-alpine
    container_name: hbutoj-redis
    restart: always
    volumes:
      - ./hbutoj/data/redis/data:/data
    networks:
      hbutoj-network:
        ipv4_address: 172.20.0.2
    ports:
      - "6379:6379"
    command: redis-server --requirepass "hoj123456" --appendonly yes
        
  hbutoj-mysql:
    image: ghcr.io/1650041940/hbutoj_database:latest
    container_name: hbutoj-mysql
    restart: always
    volumes:
      - ./hbutoj/data/mysql/data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=hoj123456
      - TZ=Asia/Shanghai
      - NACOS_USERNAME=root
      - NACOS_PASSWORD=hoj123456
    ports:
      - "3306:3306"
    networks:
      hbutoj-network:
        ipv4_address: 172.20.0.3
      
  hbutoj-nacos:
    image: nacos/nacos-server:1.4.2
    container_name: hbutoj-nacos
    restart: always
    depends_on: 
      - hbutoj-mysql
    environment:
      - JVM_XMX=384m
      - JVM_XMS=384m
      - JVM_XMN=192m
      - MODE=standalone
      - SPRING_DATASOURCE_PLATFORM=mysql
      - MYSQL_SERVICE_HOST=172.20.0.3
      - MYSQL_SERVICE_PORT=3306
      - MYSQL_SERVICE_USER=root
      - MYSQL_SERVICE_PASSWORD=Hzh&hy2020
      - MYSQL_SERVICE_DB_NAME=nacos
      - NACOS_AUTH_ENABLE=true # 开启鉴权

networks:
   hbutoj-network:
     driver: bridge
     ipam:
       config:
         - subnet: 172.20.0.0/16
```



## 文件介绍

### 1. check_nacos.sh

用于检测nacos是否启动完成，然后再执行启动backend

```shell
#!/bin/bash

while :
    do
        # 访问nacos注册中心，获取http状态码
        CODE=`curl -I -m 10 -o /dev/null -s -w %{http_code}  http://$NACOS_URL/nacos/index.html`
        # 判断状态码为200
        if [[ $CODE -eq 200 ]]; then
            # 输出绿色文字，并跳出循环
            echo -e "\033[42;34m nacos is ok \033[0m"
            break
        else
            # 暂停1秒
            sleep 1
        fi
    done

# while结束时，执行容器中的run.sh。
bash /run.sh
```

### 2. run.sh

启动backend的springboot jar包

```shell
#!/bin/sh

java -Djava.security.egd=file:/dev/./urandom -jar  /app.jar
```

### 3. Dockerfile

```dockerfile
FROM java:8

COPY *.jar /app.jar

COPY check_nacos.sh /check_nacos.sh

COPY run.sh /run.sh

ENV TZ=Asia/Shanghai

ENV BACKEND_SERVER_PORT=6688

VOLUME ["/hoj/file","/hoj/testcase"]

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

CMD ["bash","/check_nacos.sh"]

EXPOSE $BACKEND_SERVER_PORT

```

