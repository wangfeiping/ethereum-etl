# 转账交易流式处理

这个功能允许您持续监控以太坊网络的新区块，并自动导出所有转账交易（value > 0的交易）。

## 功能特点

- **持续运行**: 自动监控新区块，无需手动干预
- **断点续传**: 记录最后同步的区块，重启后自动继续
- **灵活配置**: 支持多种参数配置，适应不同需求
- **日志记录**: 详细的日志记录，便于监控和调试
- **进程管理**: 支持守护进程模式，便于生产环境部署

## 文件说明

### 核心文件

- `ethereumetl/cli/stream_transfer_transactions.py` - 流式处理主程序
- `start_transfer_stream.sh` - 启动脚本
- `stop_transfer_stream.sh` - 停止脚本
- `status_transfer_stream.sh` - 状态检查脚本

### 输出文件

- `transfer_transactions_stream.csv` - 转账交易数据文件
- `transfer_stream.log` - 日志文件
- `transfer_stream.pid` - 进程ID文件
- `last_synced_transfer_block.txt` - 最后同步区块记录

## 快速开始

### 1. 基本使用

```bash
# 启动流式处理（前台模式）
./start_transfer_stream.sh

# 启动流式处理（后台模式）
./start_transfer_stream.sh --daemon

# 检查状态
./status_transfer_stream.sh

# 停止处理
./stop_transfer_stream.sh
```

### 2. 自定义配置

```bash
# 指定开始区块
./start_transfer_stream.sh -s 18000000

# 自定义提供者URI
./start_transfer_stream.sh -p "https://mainnet.infura.io/v3/YOUR_PROJECT_ID"

# 调整同步间隔
./start_transfer_stream.sh -t 5

# 指定输出文件
./start_transfer_stream.sh -o "my_transfers.csv"

# 同时导出区块数据
./start_transfer_stream.sh --export-blocks
```

### 3. 生产环境部署

```bash
# 后台运行，指定日志文件
./start_transfer_stream.sh \
  --daemon \
  --log-file "/var/log/transfer_stream.log" \
  --pid-file "/var/run/transfer_stream.pid" \
  --output "/data/transfers.csv" \
  --lag 10 \
  --period-seconds 5
```

## 参数说明

### 启动脚本参数

| 参数 | 简写 | 默认值 | 说明 |
|------|------|--------|------|
| `--provider-uri` | `-p` | `https://mainnet.infura.io` | Web3提供者URI |
| `--start-block` | `-s` | 最新区块 | 开始区块号 |
| `--period-seconds` | `-t` | `10` | 同步间隔秒数 |
| `--batch-size` | `-b` | `100` | 批量大小 |
| `--max-workers` | `-w` | `5` | 最大工作线程数 |
| `--lag` | `-l` | `0` | 滞后区块数 |
| `--output` | `-o` | `transfer_transactions_stream.csv` | 输出文件 |
| `--log-file` | - | `transfer_stream.log` | 日志文件 |
| `--pid-file` | - | `transfer_stream.pid` | PID文件 |
| `--export-blocks` | - | `false` | 同时导出区块数据 |
| `--no-export-transactions` | - | `false` | 不导出交易数据 |
| `--daemon` | `-d` | `false` | 守护进程模式 |

### 停止脚本参数

| 参数 | 说明 |
|------|------|
| `--pid-file` | PID文件路径 |
| `--force` | 强制停止进程 |

### 状态检查脚本参数

| 参数 | 说明 |
|------|------|
| `--pid-file` | PID文件路径 |
| `--log-file` | 日志文件路径 |
| `--output-file` | 输出文件路径 |
| `--tail` | 显示日志最后N行 |
| `--follow` | 实时跟踪日志 |

## 输出文件格式

### 转账交易CSV文件

CSV文件包含以下字段：

- `hash` - 交易哈希
- `nonce` - 交易nonce
- `block_hash` - 区块哈希
- `block_number` - 区块号
- `transaction_index` - 交易索引
- `from_address` - 发送地址
- `to_address` - 接收地址
- `value` - 转账金额（wei）
- `gas` - gas限制
- `gas_price` - gas价格
- `input` - 输入数据
- `block_timestamp` - 区块时间戳

### 日志文件

日志文件记录以下信息：

- 启动和停止信息
- 同步进度
- 错误和异常
- 性能统计

## 监控和管理

### 1. 检查运行状态

```bash
# 基本状态检查
./status_transfer_stream.sh

# 显示详细日志
./status_transfer_stream.sh --tail 50

# 实时跟踪日志
./status_transfer_stream.sh --follow
```

### 2. 性能监控

```bash
# 查看进程资源使用
ps aux | grep stream_transfer_transactions

# 监控日志文件增长
tail -f transfer_stream.log

# 检查输出文件大小
ls -lh transfer_transactions_stream.csv
```

### 3. 故障排除

```bash
# 检查最后同步的区块
cat last_synced_transfer_block.txt

# 查看错误日志
grep ERROR transfer_stream.log

# 强制重启
./stop_transfer_stream.sh --force
./start_transfer_stream.sh --daemon
```

## 配置建议

### 1. 开发环境

```bash
./start_transfer_stream.sh \
  -p "https://mainnet.infura.io" \
  -s 18000000 \
  -t 30 \
  -b 10 \
  -w 2
```

### 2. 测试环境

```bash
./start_transfer_stream.sh \
  --daemon \
  -p "https://mainnet.infura.io" \
  -t 10 \
  -b 50 \
  -w 3 \
  --lag 5
```

### 3. 生产环境

```bash
./start_transfer_stream.sh \
  --daemon \
  -p "https://mainnet.infura.io/v3/YOUR_PROJECT_ID" \
  -t 5 \
  -b 100 \
  -w 5 \
  --lag 10 \
  --log-file "/var/log/transfer_stream.log" \
  --pid-file "/var/run/transfer_stream.pid" \
  --output "/data/transfers.csv"
```

## 注意事项

1. **API限制**: 确保您的Web3提供者有足够的API调用限制
2. **存储空间**: 监控输出文件大小，确保有足够的磁盘空间
3. **网络稳定性**: 建议使用稳定的网络连接
4. **错误处理**: 程序会自动重试，但建议监控日志文件
5. **数据完整性**: 使用`--lag`参数避免处理未确认的区块

## 故障排除

### 常见问题

1. **进程无法启动**
   - 检查Python环境和依赖
   - 确认Web3提供者URI有效
   - 查看错误日志

2. **同步速度慢**
   - 增加`--max-workers`参数
   - 减少`--batch-size`参数
   - 检查网络连接

3. **内存使用过高**
   - 减少`--max-workers`参数
   - 减少`--batch-size`参数
   - 增加`--period-seconds`参数

4. **输出文件过大**
   - 定期归档或压缩文件
   - 考虑使用数据库存储
   - 实现文件轮转

### 日志分析

```bash
# 查看错误
grep -i error transfer_stream.log

# 查看同步进度
grep "synced block" transfer_stream.log

# 查看性能统计
grep "exported" transfer_stream.log
```

## 扩展功能

### 1. 数据库存储

可以修改代码将数据存储到数据库而不是CSV文件：

```python
# 示例：PostgreSQL存储
--output "postgresql+pg8000://user:pass@localhost/ethereum"
```

### 2. 消息队列

可以将数据发送到消息队列：

```python
# 示例：Kafka
--output "kafka/127.0.0.1:9092"
```

### 3. 云存储

可以将数据上传到云存储：

```python
# 示例：Google Cloud Storage
--output "gs://your-bucket/transfers/"
```

## 技术支持

如果遇到问题，请：

1. 检查日志文件中的错误信息
2. 确认配置参数正确
3. 验证网络连接和API访问
4. 查看进程状态和资源使用

更多信息请参考 ethereum-etl 项目的官方文档。 