# HBUTOJ Deploy

本仓库用于部署 HBUTOJ。

维护者：1650041940（GitHub：`https://github.com/1650041940`，GHCR：`ghcr.io/1650041940`）

## 镜像发布与更新（推荐流程）

目标：你在源码仓库修改后端/前端/判题端代码后，发布到你自己的镜像仓库；部署侧只需要 `docker compose pull` 即可更新。

最短流程（你描述的标准用法）：

1) 源码仓库（构建并推送镜像）：

```bash
cd /root/source/hbutoj/tools
./hbutoj_build_and_push.sh
```

2) 部署仓库（拉取并启动）：

```bash
cd /root/services/hbutoj_deplay/standAlone
docker compose pull
docker compose up -d
```

### 1) 配置部署仓库拉取你自己的镜像

以单机部署为例：先从示例文件生成本地配置（`.env` 不会提交到仓库，避免泄露密码）：

```bash
cp -n standAlone/.env.example standAlone/.env
```

然后编辑 `standAlone/.env`：

- `HBUTOJ_IMAGE_PREFIX`：你的镜像仓库前缀（例如 `ghcr.io/<user>`）
- `HBUTOJ_IMAGE_TAG`：通用版本号/标签（仍保留，但更推荐使用下面的“组件独立 tag”）
- `HBUTOJ_BACKEND_IMAGE_TAG` / `HBUTOJ_FRONTEND_IMAGE_TAG` / `HBUTOJ_JUDGESERVER_IMAGE_TAG`：组件独立 tag（推荐，便于只更新单个服务）
- `HBUTOJ_*_IMAGE`：镜像仓库名（repo name），推荐保持与本项目一致（默认 `hbutoj_backend` 等），也可以改成你自己的命名

分布式部署对应：

```bash
cp -n distributed/main/.env.example distributed/main/.env
cp -n distributed/judgeserver/.env.example distributed/judgeserver/.env
```

再按需修改 `distributed/main/.env` 与 `distributed/judgeserver/.env`。

### 2) 从源码仓库构建并推送镜像

在源码仓库执行（假设源码仓库在 `/root/source/hbutoj`）：

```bash
cd /root/source/hbutoj
chmod +x tools/hbutoj_build_and_push.sh

export HBUTOJ_IMAGE_PREFIX=ghcr.io/<your_user>
export HBUTOJ_IMAGE_TAG=v1.0.0

# 如果你改了镜像 repo name，也要在这里一致
# export HBUTOJ_BACKEND_IMAGE=hbutoj_backend
# export HBUTOJ_FRONTEND_IMAGE=hbutoj_frontend
# export HBUTOJ_JUDGESERVER_IMAGE=hbutoj_judgeserver

./tools/hbutoj_build_and_push.sh
```

说明：部署侧 `standAlone/docker-compose.yml` 默认包含 `hbutoj-mysql-checker`（一次性 SQL 检查/更新容器）。
为了保证你在部署侧只需要 `docker compose pull && docker compose up -d` 就能更新，源码侧发布镜像时也应当包含：

- `hbutoj_backend`
- `hbutoj_frontend`
- `hbutoj_judgeserver`
- `hbutoj_database_checker`（mysql-checker）

现在 `tools/hbutoj_build_and_push.sh` 已默认构建并推送 mysql-checker；如需跳过可设置：`HBUTOJ_BUILD_MYSQL_CHECKER=false`。

常见坑：如果你是从聊天/网页复制命令，环境变量里可能混入中文标点（例如 `、`、全角逗号/空格），会导致：

```text
invalid reference format
```

排查方法：

```bash
echo "HBUTOJ_IMAGE_PREFIX=[$HBUTOJ_IMAGE_PREFIX]"
printf '%q\n' "$HBUTOJ_IMAGE_PREFIX"
```

另外提醒：`docker compose` 的变量优先级里，**当前 shell 的环境变量会覆盖 `standAlone/.env`**。
如果你之前执行过 `export HBUTOJ_MYSQL_IMAGE=...`（或其它 `HBUTOJ_*`），即使你修改了 `.env`，compose 仍可能用旧值。

排查/修复方式：

```bash
env | grep '^HBUTOJ_MYSQL_IMAGE'
unset HBUTOJ_MYSQL_IMAGE
# 或者显式覆盖
export HBUTOJ_MYSQL_IMAGE=hbutoj_database
```

### 2.1) 只发布 judgeserver（热修推荐）

当你只改了判题端（例如语言配置）时，只发布 `hbutoj-judgeserver` 更快、更稳。

在源码仓库编译 `JudgeServer`：

```bash
export HBUTOJ_IMAGE_PREFIX=ghcr.io/<your_user>
export HBUTOJ_IMAGE_TAG=v1.0.1
export HBUTOJ_JUDGESERVER_IMAGE=hbutoj_judgeserver

cd /root/source/hbutoj/hbutoj-springboot
mvn -pl JudgeServer -am clean package -DskipTests
```

把 jar 放入构建上下文（注意：该 Dockerfile 使用 `COPY *.jar`，目录里不要残留多个 jar）：

```bash
rm -f /root/services/hbutoj_deplay/src/judgeserver/*.jar
cp -f JudgeServer/target/hoj-judgeServer-*.jar /root/services/hbutoj_deplay/src/judgeserver/
```

构建并推送：

```bash
read -r -s GHCR_TOKEN
printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u <your_user> --password-stdin
unset GHCR_TOKEN

docker build -t "$HBUTOJ_IMAGE_PREFIX/$HBUTOJ_JUDGESERVER_IMAGE:$HBUTOJ_IMAGE_TAG" /root/services/hbutoj_deplay/src/judgeserver
docker push "$HBUTOJ_IMAGE_PREFIX/$HBUTOJ_JUDGESERVER_IMAGE:$HBUTOJ_IMAGE_TAG"
```

部署机切换到新版本（只更新 judgeserver）：

```bash
cd /root/services/hbutoj_deplay/standAlone
sed -i 's/^HBUTOJ_IMAGE_TAG=.*/HBUTOJ_IMAGE_TAG=v1.0.1/' .env
docker compose pull hbutoj-judgeserver
docker compose up -d hbutoj-judgeserver
```

注意：推送前需先 `docker login` 到你的镜像仓库。

以 GHCR 为例（`ghcr.io`）：

1) 先在 GitHub 个人设置生成一个 **Personal access token (classic)**，至少勾选：`write:packages`、`read:packages`。

2) 登录（交互式，最简单）：

```bash
docker login ghcr.io -u <your_user>
# Password 粘贴你的 PAT
```

或（非交互式，避免 token 出现在命令历史里）：

```bash
read -r -s GHCR_TOKEN
printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u <your_user> --password-stdin
unset GHCR_TOKEN
```

### 3) 部署侧拉取并更新

```bash
cd /root/services/hbutoj_deplay/standAlone
docker compose pull
docker compose up -d
```

注意：`standAlone/docker-compose.yml` 里包含一个一次性任务容器 `hbutoj-mysql-checker`（用于检查/执行 SQL 更新）。

- 如果你看到类似报错：`.../hoj_database_checker:latest: not found`，通常是 `standAlone/.env` 里把 `HBUTOJ_MYSQL_CHECKER_IMAGE` 配错了。
   - 正确值应为：`HBUTOJ_MYSQL_CHECKER_IMAGE=hbutoj_database_checker`
- 如果你没有把该镜像推送到自己的仓库，也可以在部署机本地构建一次（见 `src/mysql-checker/Dockerfile`）：

```bash
cd /root/services/hbutoj_deplay/src/mysql-checker
docker build -t "$HBUTOJ_MYSQL_CHECKER_IMAGE_PREFIX/$HBUTOJ_MYSQL_CHECKER_IMAGE:$HBUTOJ_MYSQL_CHECKER_IMAGE_TAG" .
```

另外，如果你看到类似报错：`.../hbutoj_database:latest: not found`，这表示 **MySQL(DB) 镜像没有推送到你配置的镜像仓库** 或者镜像名不一致。

- 正规修复方式 A（推荐，初始化最省事）：在 `src/mysql/` 目录构建并推送 DB 镜像到你配置的仓库（镜像名需与 `.env` 中 `HBUTOJ_MYSQL_IMAGE` 对齐）。
- 正规修复方式 B（适合已有数据卷、或你愿意自行初始化 DB）：在 `standAlone/.env` 设置 `HBUTOJ_MYSQL_IMAGE_FULL=mysql:8.0.43`（或其它 mysql 版本），直接使用官方 MySQL 镜像。

## 内存限制（≤ 3.9G）

单机部署的所有服务都支持在 `standAlone/.env` 中通过 `*_MEM_LIMIT` 与 `*_JAVA_OPTS` 显式收敛内存。

分布式部署同理：主服务修改 `distributed/main/.env`，判题机修改 `distributed/judgeserver/.env`。

当前默认值（见 `standAlone/docker-compose.yml` 与 `standAlone/.env`）的 `mem_limit` 合计约为：

- Redis 96M
- MySQL 512M（InnoDB buffer pool 默认 256M）
- Nacos 320M（JVM Xmx 默认 256m）
- Backend 512M（JVM Xmx 默认 320m）
- Frontend(Nginx) 96M
- JudgeServer 512M（JVM Xmx 默认 320m）
- MySQL Checker 128M
- Autoheal 32M

合计约 2208M（≈2.2G），满足“总内存 ≤ 3.9G”的目标，并预留了系统与容器运行时开销的空间。

验证方式（部署机执行）：

```bash
cd /root/services/hbutoj_deplay/standAlone
docker compose up -d
docker stats --no-stream
```

说明：该 compose 同时写了 `deploy.resources.limits.memory` 与 `mem_limit`，其中 `mem_limit` 在普通 `docker compose` 模式下可生效（不需要 Swarm）。

## 推荐 & Rating（做题/比赛）

本项目内置“每日推荐题 + 做题 rating + 比赛 rating + 排行榜”，后端与前端均已集成。

### 1) 关键字段语义

- `problem.difficulty`：难度等级（0/1/2），主要用于题目列表展示与筛选。
- `problem.difficulty_rating`：难度分（建议 600~2600），用于做题 rating 的计算与推荐排序。

说明：如果历史数据里 `difficulty_rating=0` 或缺失，后端的月度任务会按 `difficulty(0/1/2)` 给一个合理的初始区间并逐月调整。

### 2) 依赖的数据结构（来自哪些表）

- 月度题目难度调整：基于 `judge`（提交记录）统计“尝试人数/通过人数/AC用户平均提交次数”。
- 月度做题 rating：基于 `user_acproblem`（用户已 AC 题目）并结合 `judge` 统计每题尝试次数，再结合 `problem.difficulty_rating` 计算。
- 比赛 rating：基于 `contest` 与比赛排行榜（内部会做幂等处理，避免重复计算）。

### 3) 数据表（部署侧初始化已包含）

这些表在 MySQL 初始化脚本中已经包含（见 `src/mysql/hoj.sql`）：

- `user_practice_rating` / `user_practice_rating_history`
- `user_contest_rating` / `user_contest_rating_history`
- `problem_difficulty_history`
- `contest_rating_event`

### 4) 定时任务（后端已开启）

后端已启用 Spring Scheduling（`@EnableScheduling`），默认 cron：

- 每月 1 号 04:30：刷新题目难度（月度调整）+ 用户做题 rating（月度刷新）
- 每天 04:10：处理已结束比赛的 contest rating（幂等）

如果你希望更频繁/更早执行，可在源码侧调整对应 cron。

### 5) API 与前端入口

后端 API：

- `GET /api/rating/get-my`（需要登录）
- `GET /api/rating/practice-rank`（排行榜，支持分页与 `searchUser`）
- `GET /api/rating/contest-rank`（排行榜，支持分页与 `searchUser`）

前端页面：

- 排行榜菜单中已包含 “Rating Rank”，路由为 `/rating-rank`

### 6) 最小验证（部署机）

1) 访问排行榜页面：`http://<host>/rating-rank`

2) 检查接口返回：

```bash
curl -sS 'http://<host>/api/rating/practice-rank?currentPage=1&limit=10' | head
curl -sS 'http://<host>/api/rating/contest-rank?currentPage=1&limit=10' | head
```

3) 观察定时任务效果（首次需要等到 cron 执行，或你手动在后端侧触发相同逻辑）：

- `problem.difficulty_rating` 是否从 0 逐步变为合理区间
- `user_practice_rating` / `user_contest_rating` 是否有数据写入

# 环境准备

### Linux 环境

#### 1. 安装必要的依赖

```shell
sudo apt-get update && sudo apt-get install -y vim curl git
```

#### 2. 安装 Docker

1. 安装需要的包

   ```shell
   sudo apt-get update
   ```

2.  安装依赖包

   ```shell
   sudo apt-get install \
   apt-transport-https \
   ca-certificates \
   curl \
   gnupg-agent \
   software-properties-common
   ```

3. 添加 Docker 的官方 GPG 密钥

   ```shell
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
   ```

4. 设置远程仓库

   ```shell
   sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
   ```

5. 安装 Docker-CE

   ```shell
   sudo apt-get update
   sudo apt-get install docker-ce docker-ce-cli containerd.io
   ```

6. 验证是否成功

   ```shell
   sudo docker run hello-world
   ```

#### 3.  安装docker-compose

1. 下载

   ```shell
   sudo curl -L https://get.daocloud.io/docker/compose/releases/download/1.25.5/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
   ```

2. 授权

   ```shell
   sudo chmod +x /usr/local/bin/docker-compose
   ```

### Windows 环境

Windows 下的安装仅供体验，勿在生产环境使用。如有必要，请使用虚拟机安装 Linux 并将 OJ 安装在其中。

以下教程仅适用于 Win10 x64 下的 `PowerShell`

1. 安装 Windows 的 Docker 工具
2. 右击右下角 Docker 图标，选择 Settings 进行设置
3. 选择 `Shared Drives` 菜单，之后勾选你想安装 OJ 的盘符位置（例如勾选D盘），点击 `Apply`
4. 输入 Windows 的账号密码进行文件共享
5. 安装 `Python`、`pip`、`git`、`docker-compose`，安装方法自行搜索。



# 开始部署

1. 选择好需要安装的位置，运行下面命令

   ```shell
   git clone <YOUR_DEPLOY_REPO_URL> && cd <YOUR_DEPLOY_REPO_DIR>
   ```

2. 单机部署（建议服务器内存2G以上）

   > 注意：以下操作建议试用，配置大部分是默认的，实际运行请修改`docker-compose.yml`文件的配置

   ```shell
   cd standAlone && docker-compose up -d
   ```

   根据网速情况，大约十到二十分钟即可安装完毕，全程无需人工干预。

   等待命令执行完毕后，查看容器状态

   ```shell
   docker ps -a
   ```

   大概初始化启动需要一至两分钟，当看到所有的容器的状态status都为`UP`或`healthy`就代表 OJ 已经启动成功。

   > 更多自定义配置请查看**/standAlone/.env**的文件，或者/src下各组件的详情说明

   > 以下默认参数说明
   
   - 默认超级管理员账号与密码：root / hoj123456
   - 默认redis密码：hoj123456
   - 默认mysql账号与密码：root / hoj123456
   - 默认nacos管理员账号与密码：root / hoj123456
   - 默认不开启https，开启需修改文件同时提供证书文件
   - 判题并发数默认：cpu核心数*2
- 默认开启vj判题，需要手动修改添加账号与密码，如果不添加不能vj判题！
   - vj判题并发数默认：cpu核心数*4

   **登录root账号到后台查看服务状态以及到`http://ip/admin/conf`修改服务配置!**

   <u>注意：网站的注册及用户账号相关操作需要邮件系统，所以请在系统配置中配置自己的邮件服务。</u>
   
   **开启使用例如QQ邮箱提供的POP3/SMTP服务：**
   
   ```json
   Host: smtp.qq.com
   Port: 465
   Username: qq邮箱账号
   Password: 开启SMTP服务后生成的随机授权码
   ```

3. 分布式部署（默认开启rsync数据同步）

   - 主服务启动，默认不提供判题服务，请修改该启动文件配置

     ```shell
     cd distributed/main
     vim .env # 请根据文件内注释提示修改
     ```

     配置修改保存后，在`docker-compose.yml`当前路径下启动该服务

     ```shell
     docker-compose up -d
     ```

   - 判题服务启动，请修改该启动文件配置

     ```shell
     cd distributed/judgeserver
     vim .env # 请根据文件内注释提示修改
     ```

     配置修改保存后，在`docker-compose.yml`当前路径下启动该服务

     ```shell
     docker-compose up -d
     ```

   两个服务都启动完成，在浏览器输入主服务ip或域名进行访问，登录root账号到后台查看服务状态以及到`http://ip/admin/conf`修改服务配置!


> 如果需要开启https

- 单机：

   提供server.crt和server.key证书与密钥文件放置`/standAlone`目录下，与`docker-compose.yml`和`.env`文件放置同一位置，然后修改`docker-compose.yml`中的hbutoj-frontend的配置

- 分布式：提供server.crt和server.key证书与密钥文件放置`/distributed/main目录下，与`docker-compose.yml`和`.env`文件放置同一位置，然后修改`docker-compose.yml`中的hbutoj-frontend的配置

```yaml
hbutoj-frontend:
   image: ${HBUTOJ_IMAGE_PREFIX:-ghcr.io/1650041940}/${HBUTOJ_FRONTEND_IMAGE:-hbutoj_frontend}:${HBUTOJ_FRONTEND_IMAGE_TAG:-latest}
   container_name: hbutoj-frontend
    restart: always
    # 开启https，请提供证书
    volumes:
      - ./server.crt:/etc/nginx/etc/crt/server.crt
      - ./server.key:/etc/nginx/etc/crt/server.key
    environment:
      - SERVER_NAME=localhost  # 提供你的域名！！！！
      - BACKEND_SERVER_HOST=${BACKEND_HOST:-172.20.0.5} # backend后端服务地址
      - BACKEND_SERVER_PORT=${BACKEND_PORT:-6688} # backend后端服务端口号
      - USE_HTTPS=true # 使用https请设置为true
    ports:
      - "80:80"
      - "443:443"
    networks:
         hbutoj-network:
        ipv4_address: 172.20.0.6
```



# 最后

## 项目链接

- GitHub：https://github.com/1650041940