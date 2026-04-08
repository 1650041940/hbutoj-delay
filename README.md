# HBUTOJ Deploy

本仓库提供 HBUTOJ 的 Docker Compose 部署配置（单机/分布式）以及相关构建上下文（backend/frontend/judgeserver/mysql-checker）。

## 快速开始（单机 standAlone）

1) 准备配置文件：

```bash
cd <repo_root>
cp -n standAlone/.env.example standAlone/.env
```

2) 编辑 `standAlone/.env`，至少配置你的镜像仓库前缀与 tag：

- `HBUTOJ_IMAGE_PREFIX`：例如 `ghcr.io/<your_user>`
- `HBUTOJ_*_IMAGE_TAG`：各组件 tag（推荐分别设置，便于只更新单个服务）

3) 启动：

```bash
cd <repo_root>/standAlone
docker compose pull
docker compose up -d
```

## 从源码仓库构建并推送镜像（推荐）

在源码仓库执行构建脚本（会把产物同步到本仓库的 `src/*` 构建上下文，并构建/推送镜像）：

```bash
cd <source_repo_root>
chmod +x tools/hbutoj_build_and_push.sh

export HBUTOJ_IMAGE_PREFIX=ghcr.io/<your_user>
export HBUTOJ_BACKEND_IMAGE_TAG=v1.0.0
export HBUTOJ_FRONTEND_IMAGE_TAG=v1.0.0
export HBUTOJ_JUDGESERVER_IMAGE_TAG=v1.0.0
export HBUTOJ_MYSQL_CHECKER_IMAGE_TAG=v1.0.0

./tools/hbutoj_build_and_push.sh
```

部署机更新：

```bash
cd <repo_root>/standAlone
docker compose pull
docker compose up -d
```

## 数据目录（重要）

Compose 通过 `HBUTOJ_DATA_DIRECTORY` 指定宿主机数据根目录。

- 推荐目录：`standAlone/hbutoj/`

如果你历史数据在 `standAlone/hoj/`，请使用下方迁移脚本迁移到 `standAlone/hbutoj/`。

## 数据目录迁移（可回滚脚本）

仓库提供迁移脚本用于把 `standAlone/hoj/` 迁移为 `standAlone/hbutoj/`（默认 dry-run，不会直接改线上数据）：

```bash
cd <repo_root>/standAlone
bash migrate_data_dir_hoj_to_hbutoj.sh --dry-run
```

确认无误后再执行真实迁移（建议在维护窗口执行）：

```bash
bash migrate_data_dir_hoj_to_hbutoj.sh --apply
```

## 常见问题

- `invalid reference format`：通常是环境变量里混入了中文标点/不可见字符；用 `printf '%q\n' "$HBUTOJ_IMAGE_PREFIX"` 排查。
- 环境变量覆盖 `.env`：当前 shell 里导出的 `HBUTOJ_*` 会覆盖 `.env`，必要时 `unset` 再执行 `docker compose`。
