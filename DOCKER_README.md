# Docker 转账交易流式处理

这个文档说明如何使用 Docker 运行转账交易流式处理功能。

## 快速开始

### 1. 一键启动

```bash
# 快速启动（推荐）
./quick-start-docker.sh
```

### 2. 手动启动

```bash
# 1. 创建环境变量文件
cp env.example .env

# 2. 编辑 .env 文件，设置您的 Infura 项目ID
# 特别是 PROVIDER_URI 参数

# 3. 启动服务
docker-compose -f docker-compose.simple.yml up -d
```

## 文件说明

### Docker 配置文件

- `docker-compose.simple.yml` - 简化版 Docker Compose 配置
- `docker-compose.transfer-stream.yml` - 完整版 Docker Compose 配置（包含监控服务）
- `Dockerfile` - Docker 镜像构建文件

### 启动脚本

- `quick-start-docker.sh` - 快速启动脚本
- `docker-start-transfer-stream.sh` - 完整功能启动脚本

### 配置文件

- `env.example` - 环境变量示例文件
- `.env` - 环境变量配置文件（需要创建）

## 使用方法

### 基本操作

```bash
# 启动服务
docker-compose -f docker-compose.simple.yml up -d

# 查看日志
docker-compose -f docker-compose.simple.yml logs -f

# 停止服务
docker-compose -f docker-compose.simple.yml down

# 重启服务
docker-compose -f docker-compose.simple.yml restart

# 查看状态
docker-compose -f docker-compose.simple.yml ps
```

### 使用完整功能脚本

```bash
# 启动服务
./docker-start-transfer-stream.sh -s

# 启动服务和监控
./docker-start-transfer-stream.sh -s -m

# 查看日志
./docker-start-transfer-stream.sh -l

# 停止服务
./docker-start-transfer-stream.sh -S

# 清理所有数据
./docker-start-transfer-stream.sh -c
```

## 环境变量配置

### 必需配置

在 `.env` 文件中设置以下参数：

```bash
# Web3 提供者（必需）
PROVIDER_URI=https://mainnet.infura.io/v3/YOUR_PROJECT_ID

# 区块同步配置
START_BLOCK=18000000
PERIOD_SECONDS=10
BATCH_SIZE=100
MAX_WORKERS=5
LAG=0

# 文件路径
OUTPUT_FILE=/app/data/transfer_transactions.csv
LOG_FILE=/app/logs/transfer_stream.log
PID_FILE=/app/state/transfer_stream.pid
LAST_SYNCED_BLOCK_FILE=/app/state/last_synced_transfer_block.txt

# 导出选项
EXPORT_BLOCKS=false
EXPORT_TRANSACTIONS=true
```

### 配置说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `PROVIDER_URI` | Web3提供者URI | `https://mainnet.infura.io` |
| `START_BLOCK` | 开始区块号 | 最新区块 |
| `PERIOD_SECONDS` | 同步间隔秒数 | `10` |
| `BATCH_SIZE` | 批量大小 | `100` |
| `MAX_WORKERS` | 最大工作线程 | `5` |
| `LAG` | 滞后区块数 | `0` |
| `OUTPUT_FILE` | 输出文件路径 | `/app/data/transfer_transactions.csv` |
| `LOG_FILE` | 日志文件路径 | `/app/logs/transfer_stream.log` |
| `PID_FILE` | PID文件路径 | `/app/state/transfer_stream.pid` |
| `LAST_SYNCED_BLOCK_FILE` | 同步状态文件 | `/app/state/last_synced_transfer_block.txt` |
| `EXPORT_BLOCKS` | 是否导出区块 | `false` |
| `EXPORT_TRANSACTIONS` | 是否导出交易 | `true` |

## 数据存储

### 目录结构

```
ethereum-etl/
├── data/                           # 数据输出目录
│   └── transfer_transactions.csv   # 转账交易数据
├── logs/                           # 日志目录
│   └── transfer_stream.log         # 运行日志
├── state/                          # 状态文件目录
│   ├── transfer_stream.pid         # 进程ID文件
│   └── last_synced_transfer_block.txt  # 最后同步区块
└── config/                         # 配置文件目录
```

### 数据文件

- **transfer_transactions.csv** - 转账交易数据文件
- **transfer_stream.log** - 详细的运行日志
- **last_synced_transfer_block.txt** - 记录最后同步的区块号

## 监控和管理

### 1. 查看服务状态

```bash
# 查看容器状态
docker-compose -f docker-compose.simple.yml ps

# 查看资源使用
docker stats ethereum-etl-transfer-stream

# 查看健康检查
docker inspect ethereum-etl-transfer-stream | grep Health -A 10
```

### 2. 日志管理

```bash
# 实时查看日志
docker-compose -f docker-compose.simple.yml logs -f

# 查看最近100行日志
docker-compose -f docker-compose.simple.yml logs --tail=100

# 查看错误日志
docker-compose -f docker-compose.simple.yml logs | grep ERROR
```

### 3. 数据监控

```bash
# 查看数据文件大小
ls -lh data/transfer_transactions.csv

# 查看最后同步的区块
cat state/last_synced_transfer_block.txt

# 查看数据行数
wc -l data/transfer_transactions.csv
```

## 高级配置

### 1. 使用完整版配置

```bash
# 使用完整版配置（包含监控服务）
docker-compose -f docker-compose.transfer-stream.yml up -d
```

### 2. 自定义配置

```bash
# 创建自定义环境变量文件
cp env.example my-config.env

# 编辑配置
vim my-config.env

# 使用自定义配置启动
docker-compose -f docker-compose.simple.yml --env-file my-config.env up -d
```

### 3. 数据库输出

```bash
# 在 .env 文件中设置数据库输出
OUTPUT_FILE=postgresql+pg8000://user:pass@localhost/ethereum
```

### 4. 消息队列输出

```bash
# 在 .env 文件中设置Kafka输出
OUTPUT_FILE=kafka/127.0.0.1:9092
```

## 故障排除

### 常见问题

1. **容器启动失败**
   ```bash
   # 查看详细错误信息
   docker-compose -f docker-compose.simple.yml logs
   
   # 检查环境变量
   docker-compose -f docker-compose.simple.yml config
   ```

2. **网络连接问题**
   ```bash
   # 检查网络连接
   docker exec ethereum-etl-transfer-stream ping -c 3 mainnet.infura.io
   
   # 检查DNS解析
   docker exec ethereum-etl-transfer-stream nslookup mainnet.infura.io
   ```

3. **磁盘空间不足**
   ```bash
   # 检查磁盘使用情况
   df -h
   
   # 清理Docker缓存
   docker system prune -f
   ```

4. **权限问题**
   ```bash
   # 检查目录权限
   ls -la data/ logs/ state/
   
   # 修复权限
   sudo chown -R $USER:$USER data/ logs/ state/
   ```

### 日志分析

```bash
# 查看启动日志
docker-compose -f docker-compose.simple.yml logs transfer-stream

# 查看错误
docker-compose -f docker-compose.simple.yml logs | grep -i error

# 查看同步进度
docker-compose -f docker-compose.simple.yml logs | grep "synced block"
```

## 性能优化

### 1. 资源限制

在 `docker-compose.simple.yml` 中添加资源限制：

```yaml
services:
  transfer-stream:
    # ... 其他配置 ...
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

### 2. 存储优化

```bash
# 使用命名卷而不是绑定挂载
volumes:
  - transfer_data:/app/data
  - transfer_logs:/app/logs
  - transfer_state:/app/state
```

### 3. 网络优化

```bash
# 使用自定义网络
networks:
  ethereum_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## 生产环境部署

### 1. 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB RAM
- 至少 100GB 可用磁盘空间
- 稳定的网络连接

### 2. 推荐配置

```bash
# 生产环境 .env 配置
PROVIDER_URI=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
START_BLOCK=
PERIOD_SECONDS=5
BATCH_SIZE=100
MAX_WORKERS=5
LAG=10
OUTPUT_FILE=/app/data/transfer_transactions.csv
LOG_FILE=/app/logs/transfer_stream.log
PID_FILE=/app/state/transfer_stream.pid
LAST_SYNCED_BLOCK_FILE=/app/state/last_synced_transfer_block.txt
EXPORT_BLOCKS=false
EXPORT_TRANSACTIONS=true
```

### 3. 监控脚本

```bash
#!/bin/bash
# 监控脚本示例
if ! docker-compose -f docker-compose.simple.yml ps | grep -q "Up"; then
    echo "Transfer stream service is down, restarting..."
    docker-compose -f docker-compose.simple.yml restart
fi
```

## 备份和恢复

### 1. 数据备份

```bash
# 备份数据文件
tar -czf transfer_data_backup_$(date +%Y%m%d).tar.gz data/ state/

# 备份配置
cp .env .env.backup.$(date +%Y%m%d)
```

### 2. 数据恢复

```bash
# 恢复数据
tar -xzf transfer_data_backup_20231201.tar.gz

# 恢复配置
cp .env.backup.20231201 .env
```

## 总结

Docker 部署提供了以下优势：

✅ **环境隔离** - 避免依赖冲突  
✅ **易于部署** - 一键启动和停止  
✅ **可移植性** - 在任何支持Docker的环境中运行  
✅ **资源管理** - 精确控制资源使用  
✅ **监控集成** - 内置健康检查和日志管理  
✅ **扩展性** - 支持多实例部署  

现在您可以轻松地在 Docker 环境中运行转账交易流式处理功能！ 