# Ethereum ETL Docker 使用指南

## 概述

本指南介绍如何使用Docker来运行Ethereum ETL v2.4.2。

## 快速开始

### 1. 构建Docker镜像

#### 标准版本（推荐用于开发）
使用提供的构建脚本：

```bash
./build-docker.sh
```

或者手动构建：

```bash
docker build -t ethereum-etl:2.4.2 .
```

#### 生产版本（包含Tini，推荐用于生产）
```bash
docker build -f Dockerfile.with-tini -t ethereum-etl:2.4.2-production .
```

**注意**：生产版本包含Tini进程管理器，提供更好的信号处理和进程管理。

### 2. 验证镜像

```bash
docker run --rm ethereum-etl:2.4.2 --help
```

## 使用方法

### 导出区块和交易数据

```bash
docker run -v $(pwd)/output:/output ethereum-etl:2.4.2 export_all \
  --start-block 0 \
  --end-block 1000000 \
  --batch-size 100 \
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
  --output-dir /output
```

### 流式处理区块链数据

```bash
docker run -v $(pwd)/output:/output ethereum-etl:2.4.2 stream \
  --start-block 500000 \
  --entity-types block,transaction,log,token_transfer \
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
  --output /output/stream_output.json
```

### 导出代币转账

```bash
docker run -v $(pwd)/output:/output ethereum-etl:2.4.2 export_token_transfers \
  --start-block 0 \
  --end-block 1000000 \
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
  --output /output/token_transfers.csv
```

## 使用Docker Compose

### 1. 启动基础服务

```bash
docker-compose up -d ethereum-etl
```

### 2. 运行导出任务

```bash
docker-compose up ethereum-etl-export
```

### 3. 启动流式处理

```bash
docker-compose up ethereum-etl-stream
```

## 配置说明

### 环境变量

- `PYTHONUNBUFFERED=1`: 确保Python输出不被缓存
- `PYTHONDONTWRITEBYTECODE=1`: 不生成.pyc文件

### 卷挂载

- `./output:/output`: 输出目录
- `./config:/config`: 配置文件目录（可选）

### 网络

默认使用bridge网络，可以通过docker-compose.yml自定义。

## 生产环境部署

### 1. 使用特定版本标签

```bash
docker run ethereum-etl:2.4.2
```

### 2. 资源限制

```bash
docker run --memory=2g --cpus=2 ethereum-etl:2.4.2
```

### 3. 健康检查

镜像包含健康检查，可以通过以下方式查看：

```bash
docker inspect ethereum-etl:2.4.2 | grep Health -A 10
```

## 故障排除

### 1. 权限问题

如果遇到权限问题，确保输出目录有正确的权限：

```bash
mkdir -p output
chmod 755 output
```

### 2. 网络问题

如果无法连接到以太坊节点，检查provider-uri是否正确：

```bash
# 测试连接
docker run --rm ethereum-etl:2.4.2 python -c "
from web3 import Web3
w3 = Web3(Web3.HTTPProvider('https://mainnet.infura.io/v3/YOUR_PROJECT_ID'))
print('Connected:', w3.isConnected())
"
```

### 3. 内存不足

如果遇到内存不足，增加Docker内存限制：

```bash
docker run --memory=4g ethereum-etl:2.4.2
```

## 性能优化

### 1. 批量大小

根据可用内存调整batch-size：

```bash
--batch-size 50  # 小内存
--batch-size 200 # 大内存
```

### 2. 并发工作线程

```bash
--max-workers 4  # 根据CPU核心数调整
```

### 3. 输出格式

使用CSV格式比JSON更快：

```bash
--output blocks.csv  # 更快
--output blocks.json # 更慢但更灵活
```

## 监控和日志

### 1. 查看容器日志

```bash
docker logs ethereum-etl
```

### 2. 实时监控

```bash
docker stats ethereum-etl
```

### 3. 进入容器调试

```bash
docker exec -it ethereum-etl bash
```

## 安全考虑

1. 镜像使用非root用户运行
2. 定期更新基础镜像
3. 不要在容器中存储敏感信息
4. 使用私有网络隔离容器

## 支持的命令

完整的命令列表可以通过以下方式查看：

```bash
docker run --rm ethereum-etl:2.4.2 --help
```

主要命令包括：
- `export_all`: 导出所有数据
- `export_blocks_and_transactions`: 导出区块和交易
- `export_token_transfers`: 导出代币转账
- `export_receipts_and_logs`: 导出收据和日志
- `export_contracts`: 导出合约信息
- `export_traces`: 导出交易追踪
- `stream`: 流式处理

## 版本信息

- **Docker镜像版本**: 2.4.2
- **Python版本**: 3.9-slim
- **基础镜像**: python:3.9-slim
- **Tini版本**: v0.19.0（仅生产版本）

## 关于Tini

Tini是一个轻量级的进程管理器，专门为Docker容器设计。在生产环境中使用Tini可以：

1. **优雅关闭**：确保长时间运行的任务能够正确保存状态
2. **信号处理**：正确处理SIGTERM等系统信号
3. **进程清理**：自动清理僵尸进程，防止内存泄漏
4. **稳定性**：提高容器运行的可靠性

### 使用建议

- **开发环境**：使用标准版本（Dockerfile）
- **生产环境**：使用生产版本（Dockerfile.with-tini）
- **替代方案**：可以使用 `docker run --init` 选项

详细说明请参考 [TINI_EXPLANATION.md](TINI_EXPLANATION.md) 