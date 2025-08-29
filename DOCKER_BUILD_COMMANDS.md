# Docker 构建命令总结

## 成功构建的 Docker 命令

### 1. 基本构建命令（推荐）

```bash
# 构建镜像
docker build \
    -f Dockerfile.minimal \
    -t ethereum-etl-transfer-stream:latest \
    .

# 验证构建
docker run --rm ethereum-etl-transfer-stream:latest \
    python ethereumetl/cli/stream_transfer_transactions.py --help
```

### 2. 带标签的构建命令

```bash
# 构建多个标签
docker build \
    -f Dockerfile.minimal \
    -t ethereum-etl-transfer-stream:latest \
    -t ethereum-etl-transfer-stream:v1.0.0 \
    -t ethereum-etl-transfer-stream:$(date +%Y%m%d) \
    .
```

### 3. 带构建参数的完整命令

```bash
docker build \
    -f Dockerfile.minimal \
    -t ethereum-etl-transfer-stream:latest \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") \
    --no-cache \
    .
```

## 使用示例

### 1. 基本运行

```bash
# 创建本地目录
mkdir -p ./data ./logs ./state

# 运行容器
docker run -it \
    -v $(pwd)/data:/app/data \
    -v $(pwd)/logs:/app/logs \
    -v $(pwd)/state:/app/state \
    ethereum-etl-transfer-stream:latest \
    python ethereumetl/cli/stream_transfer_transactions.py \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv \
    --period-seconds 10 \
    --batch-size 100
```

### 2. 后台运行

```bash
docker run -d \
    --name ethereum-etl-transfer \
    -v $(pwd)/data:/app/data \
    -v $(pwd)/logs:/app/logs \
    -v $(pwd)/state:/app/state \
    ethereum-etl-transfer-stream:latest \
    python ethereumetl/cli/stream_transfer_transactions.py \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv \
    --period-seconds 10 \
    --batch-size 100
```

### 3. 使用环境变量

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
    ethereum-etl-transfer-stream:latest \
    python ethereumetl/cli/stream_transfer_transactions.py
```

## 镜像信息

### 镜像大小
- **基础镜像**: python:3.9-slim (~29MB)
- **应用代码**: ~10MB
- **Python 依赖**: ~250MB
- **总大小**: ~280MB

### 包含的文件
```
/app/
├── quick-start-docker.sh                    # 快速启动脚本
├── ethereumetl/                             # 以太坊 ETL 模块
├── blockchainetl/                           # 区块链 ETL 基础模块
├── setup.py                                 # Python 包配置
├── data/                                    # 数据输出目录
├── logs/                                    # 日志目录
├── state/                                   # 状态文件目录
└── config/                                  # 配置目录
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
    python ethereumetl/cli/stream_transfer_transactions.py \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv
```

### 2. 网络优化

```bash
# 使用主机网络（提高网络性能）
docker run -it \
    --network host \
    ethereum-etl-transfer-stream:latest \
    python ethereumetl/cli/stream_transfer_transactions.py \
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
    python ethereumetl/cli/stream_transfer_transactions.py \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv
```

## 故障排除

### 1. 构建失败

```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建（不使用缓存）
docker build --no-cache -f Dockerfile.minimal -t ethereum-etl-transfer-stream:latest .
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

## 推送镜像

```bash
# 标记镜像
docker tag ethereum-etl-transfer-stream:latest your-registry/ethereum-etl-transfer-stream:latest

# 推送镜像
docker push your-registry/ethereum-etl-transfer-stream:latest
```

## 总结

这个 Docker 镜像成功打包了：
1. ✅ `quick-start-docker.sh` - 快速启动脚本
2. ✅ `ethereumetl/cli/stream_transfer_transactions.py` - 流式处理脚本
3. ✅ 所有必要的依赖模块
4. ✅ 正确的文件权限和目录结构
5. ✅ 可用的 Python 环境

镜像大小约 280MB，包含了完整的以太坊 ETL 功能，可以立即使用。 