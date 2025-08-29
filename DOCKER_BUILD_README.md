# Docker 构建说明

## 概述

本文档提供了打包 `quick-start-docker.sh` 和 `ethereumetl/cli/stream_transfer_transactions.py` 的 Docker 构建命令和说明。

## 文件结构

```
ethereum-etl/
├── quick-start-docker.sh                    # 快速启动脚本
├── ethereumetl/cli/stream_transfer_transactions.py  # 流式处理脚本
├── Dockerfile.simple                        # 简化版 Dockerfile
├── .dockerignore.simple                     # Docker 忽略文件
├── build-transfer-stream.sh                 # 构建脚本
└── DOCKER_BUILD_README.md                   # 本说明文档
```

## 构建命令

### 方法1：使用构建脚本（推荐）

```bash
# 给脚本执行权限
chmod +x build-transfer-stream.sh

# 执行构建
./build-transfer-stream.sh
```

### 方法2：直接使用 Docker build 命令

```bash
# 基本构建命令
docker build \
    -f Dockerfile.simple \
    -t ethereum-etl-transfer-stream:latest \
    .

# 带构建参数的完整命令
docker build \
    -f Dockerfile.simple \
    -t ethereum-etl-transfer-stream:latest \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") \
    --no-cache \
    .
```

### 方法3：多阶段构建（优化镜像大小）

```bash
# 创建多阶段构建 Dockerfile
cat > Dockerfile.multi-stage << 'EOF'
# 构建阶段
FROM python:3.9-slim as builder

WORKDIR /app
COPY setup.py .
COPY ethereumetl/ ./ethereumetl/

RUN pip install --upgrade pip && \
    pip install -e .[streaming]

# 运行阶段
FROM python:3.9-slim

WORKDIR /app
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY quick-start-docker.sh /app/
COPY ethereumetl/cli/stream_transfer_transactions.py /app/ethereumetl/cli/

RUN chmod +x /app/quick-start-docker.sh && \
    mkdir -p /app/data /app/logs /app/state /app/config

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["python", "ethereumetl/cli/stream_transfer_transactions.py", "--help"]
EOF

# 构建多阶段镜像
docker build -f Dockerfile.multi-stage -t ethereum-etl-transfer-stream:optimized .
```

## 使用示例

### 1. 查看帮助信息

```bash
docker run ethereum-etl-transfer-stream:latest --help
```

### 2. 基本运行

```bash
docker run -it ethereum-etl-transfer-stream:latest \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv
```

### 3. 挂载数据目录

```bash
# 创建本地目录
mkdir -p ./data ./logs ./state

# 运行容器并挂载目录
docker run -it \
    -v $(pwd)/data:/app/data \
    -v $(pwd)/logs:/app/logs \
    -v $(pwd)/state:/app/state \
    ethereum-etl-transfer-stream:latest \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv \
    --period-seconds 10 \
    --batch-size 100
```

### 4. 后台运行

```bash
docker run -d \
    --name ethereum-etl-transfer \
    -v $(pwd)/data:/app/data \
    -v $(pwd)/logs:/app/logs \
    -v $(pwd)/state:/app/state \
    ethereum-etl-transfer-stream:latest \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv \
    --period-seconds 10 \
    --batch-size 100
```

### 5. 使用环境变量

```bash
# 创建环境变量文件
cat > .env << EOF
PROVIDER_URI=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
START_BLOCK=18500000
PERIOD_SECONDS=10
BATCH_SIZE=100
MAX_WORKERS=5
LAG=0
OUTPUT_FILE=/app/data/transfer_transactions.csv
LOG_FILE=/app/logs/transfer_stream.log
PID_FILE=/app/state/transfer_stream.pid
LAST_SYNCED_BLOCK_FILE=/app/state/last_synced_transfer_block.txt
EOF

# 使用环境变量运行
docker run -it \
    --env-file .env \
    -v $(pwd)/data:/app/data \
    -v $(pwd)/logs:/app/logs \
    -v $(pwd)/state:/app/state \
    ethereum-etl-transfer-stream:latest
```

## 监控和管理

### 查看容器状态

```bash
# 查看运行中的容器
docker ps

# 查看容器日志
docker logs ethereum-etl-transfer

# 实时查看日志
docker logs -f ethereum-etl-transfer
```

### 停止和重启

```bash
# 停止容器
docker stop ethereum-etl-transfer

# 启动容器
docker start ethereum-etl-transfer

# 重启容器
docker restart ethereum-etl-transfer

# 删除容器
docker rm ethereum-etl-transfer
```

## 性能优化

### 1. 资源限制

```bash
docker run -it \
    --memory=2g \
    --cpus=2 \
    --memory-swap=4g \
    ethereum-etl-transfer-stream:latest \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv
```

### 2. 网络优化

```bash
# 使用主机网络（提高网络性能）
docker run -it \
    --network host \
    ethereum-etl-transfer-stream:latest \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv
```

### 3. 存储优化

```bash
# 使用命名卷
docker volume create ethereum-etl-data
docker volume create ethereum-etl-logs
docker volume create ethereum-etl-state

docker run -it \
    -v ethereum-etl-data:/app/data \
    -v ethereum-etl-logs:/app/logs \
    -v ethereum-etl-state:/app/state \
    ethereum-etl-transfer-stream:latest \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv
```

## 故障排除

### 1. 构建失败

```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建（不使用缓存）
docker build --no-cache -f Dockerfile.simple -t ethereum-etl-transfer-stream:latest .
```

### 2. 运行失败

```bash
# 检查容器日志
docker logs ethereum-etl-transfer

# 进入容器调试
docker exec -it ethereum-etl-transfer /bin/bash

# 检查文件权限
docker exec ethereum-etl-transfer ls -la /app/
```

### 3. 网络问题

```bash
# 测试网络连接
docker run ethereum-etl-transfer-stream:latest \
    python -c "import requests; print(requests.get('https://mainnet.infura.io').status_code)"
```

## 镜像标签策略

```bash
# 版本标签
docker build -f Dockerfile.simple -t ethereum-etl-transfer-stream:v1.0.0 .

# 日期标签
docker build -f Dockerfile.simple -t ethereum-etl-transfer-stream:$(date +%Y%m%d) .

# 多标签
docker build -f Dockerfile.simple \
    -t ethereum-etl-transfer-stream:latest \
    -t ethereum-etl-transfer-stream:v1.0.0 \
    -t ethereum-etl-transfer-stream:$(date +%Y%m%d) \
    .
```

## 推送镜像

```bash
# 标记镜像
docker tag ethereum-etl-transfer-stream:latest your-registry/ethereum-etl-transfer-stream:latest

# 推送镜像
docker push your-registry/ethereum-etl-transfer-stream:latest
``` 