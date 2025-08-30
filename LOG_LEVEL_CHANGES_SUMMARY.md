# 日志级别修改总结

## 修改概述

根据用户需求，已将转账交易信息的日志输出级别从 `INFO` 改为 `WARNING`，以便在日志中更容易识别转账交易数据。

## 修改内容

### 1. 核心修改

**文件**: `ethereum-etl/ethereumetl/jobs/exporters/transfer_transactions_exporter.py`

**修改内容**: 将转账交易信息的日志输出从 `logger.info()` 改为 `logger.warning()`

```python
# 修改前
self.logger.info(f"ETH Transfer - Block: {block_number}, Hash: {transaction_hash}, ...")

# 修改后
self.logger.warning(f"ETH Transfer - Block: {block_number}, Hash: {transaction_hash}, ...")
```

### 2. 流式处理脚本增强

**文件**: `ethereum-etl/ethereumetl/cli/stream_transfer_transactions.py`

**新增功能**: 添加 `--log-level` 选项，支持动态配置日志级别

```bash
# 默认使用WARNING级别，只显示转账信息
python3 -m ethereumetl.cli.stream_transfer_transactions --log-level WARNING

# 显示所有信息
python3 -m ethereumetl.cli.stream_transfer_transactions --log-level INFO
```

### 3. 测试和示例更新

- **测试脚本**: `test_transfer_logging.py` - 更新日志级别为WARNING
- **示例脚本**: `example_transfer_streaming.py` - 更新日志级别为WARNING
- **新增示例**: `log_level_example.py` - 展示不同日志级别的效果

## 日志级别说明

### 转账交易信息输出级别

| 转账类型 | 日志级别 | 输出内容 |
|----------|----------|----------|
| ETH转账 | WARNING | 区块号、交易哈希、发送地址、接收地址、类型标记 |
| ERC20转账 | WARNING | 区块号、交易哈希、发送地址、接收地址、合约地址 |
| 其他转账 | WARNING | 区块号、交易哈希、发送地址、接收地址 |
| 统计信息 | INFO | 处理的转账交易总数 |

### 日志级别对比

| 级别 | 显示内容 | 适用场景 |
|------|----------|----------|
| DEBUG | 所有日志信息 | 调试开发 |
| INFO | INFO及以上级别 | 一般监控 |
| **WARNING** | **只显示转账信息** | **推荐使用** |
| ERROR | 只显示错误信息 | 错误排查 |

## 使用方法

### 1. 命令行使用

#### 推荐配置（只显示转账信息）
```bash
python3 -m ethereumetl.cli.stream_transfer_transactions \
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
  --start-block 19000000 \
  --log-level WARNING
```

#### 显示所有信息
```bash
python3 -m ethereumetl.cli.stream_transfer_transactions \
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
  --start-block 19000000 \
  --log-level INFO
```

### 2. 编程使用

```python
import logging

# 推荐配置 - 只显示转账信息
logging.basicConfig(
    level=logging.WARNING,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# 或者通过环境变量
import os
log_level = os.getenv('LOG_LEVEL', 'WARNING')
logging.basicConfig(level=getattr(logging, log_level))
```

### 3. 环境变量配置

```bash
# 设置环境变量
export LOG_LEVEL=WARNING

# 运行程序
python3 -m ethereumetl.cli.stream_transfer_transactions
```

## 输出示例

### WARNING级别输出（推荐）
```
2025-08-30 22:49:58,783 - TransferTransactionConverter - WARNING - ETH Transfer - Block: 19000001, Hash: 0x1234..., From: 0x742d35..., To: 0x742d35..., Type: ETH
2025-08-30 22:49:58,784 - TransferTransactionConverter - WARNING - ERC20 Transfer - Block: 19000002, Hash: 0xabcd..., From: 0x742d35..., To: 0xdac17f..., Contract: 0xdac17f...
```

### INFO级别输出
```
2025-08-30 22:49:58,783 - TransferTransactionConverter - WARNING - ETH Transfer - Block: 19000001, Hash: 0x1234..., From: 0x742d35..., To: 0x742d35..., Type: ETH
2025-08-30 22:49:58,784 - TransferTransactionConverter - WARNING - ERC20 Transfer - Block: 19000002, Hash: 0xabcd..., From: 0x742d35..., To: 0xdac17f..., Contract: 0xdac17f...
2025-08-30 22:49:58,785 - ExportTransferTransactionsJob - INFO - Block 19000001: Found 2 transfer transactions out of 150 total transactions
2025-08-30 22:49:58,786 - BatchWorkExecutor - INFO - Processed 100 blocks
```

## 优势

1. **更容易识别**: WARNING级别的日志在大多数日志配置中都会显示
2. **避免信息过载**: 不会与INFO级别的其他日志信息混在一起
3. **便于过滤**: 可以通过日志级别轻松过滤出转账信息
4. **灵活配置**: 支持动态配置不同的日志级别
5. **向后兼容**: 不影响现有功能，只是改变了日志输出方式

## 测试验证

运行以下命令验证修改效果：

```bash
# 测试转账识别功能
python3 test_transfer_logging.py

# 查看日志级别示例
python3 log_level_example.py

# 运行示例
python3 example_transfer_streaming.py
```

## 总结

通过将转账交易信息的日志级别从INFO改为WARNING，现在可以：

1. **更容易在日志中识别转账交易**
2. **避免与其他INFO级别的日志信息混淆**
3. **提供灵活的日志级别配置选项**
4. **保持向后兼容性**

推荐在生产环境中使用 `--log-level WARNING` 来只显示转账交易信息，这样可以更清晰地监控转账活动。 