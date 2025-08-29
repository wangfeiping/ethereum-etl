# 转账交易导出器使用说明

## 概述

转账交易导出器是一个自定义的Ethereum ETL组件，专门用于导出以太坊区块链中的转账交易（即value > 0的交易），并通过日志实时输出区块高度和交易哈希信息。

## 功能特性

### 核心功能
- ✅ **智能过滤**：自动识别并过滤出转账交易（value > 0）
- ✅ **实时日志**：输出每个转账交易的区块高度和交易哈希
- ✅ **统计信息**：每1000个转账交易输出一次统计
- ✅ **完整数据**：导出转账交易的完整字段信息
- ✅ **批量处理**：支持批量处理大量区块数据

### 日志输出示例
```
2025-08-29 04:45:12,345 - TransferTransactionConverter - INFO - Transfer Transaction Found - Block: 1000, Hash: 0x1234567890abcdef...
2025-08-29 04:45:12,346 - TransferTransactionConverter - INFO - Transfer Transaction Found - Block: 1001, Hash: 0xabcdef1234567890...
2025-08-29 04:45:12,347 - TransferTransactionConverter - INFO - Total transfer transactions processed: 1000
```

## 文件结构

### 核心文件
```
ethereum-etl/
├── ethereumetl/
│   ├── jobs/
│   │   ├── exporters/
│   │   │   └── transfer_transactions_exporter.py    # 转账交易导出器
│   │   └── export_transfer_transactions_job.py      # 导出任务
│   └── cli/
│       └── export_transfer_transactions.py          # CLI命令
├── test_transfer_exporter.py                        # 测试脚本
└── TRANSFER_EXPORTER_README.md                      # 本说明文档
```

## 使用方法

### 1. 命令行使用

#### 基本用法
```bash
# 导出指定区块范围的转账交易
ethereumetl export_transfer_transactions \
  --start-block 1000000 \
  --end-block 1000100 \
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
  --transfer-transactions-output transfer_transactions.csv
```

#### 完整参数
```bash
ethereumetl export_transfer_transactions \
  --start-block 1000000 \                    # 起始区块
  --end-block 1000100 \                      # 结束区块
  --batch-size 100 \                         # 批量大小
  --max-workers 5 \                          # 最大工作线程数
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \  # 以太坊节点URI
  --transfer-transactions-output transfer_transactions.csv \     # 输出文件
  --export-blocks \                          # 是否导出区块信息
  --export-transactions                      # 是否导出交易信息
```

### 2. Docker使用

#### 构建镜像
```bash
# 重新构建包含新功能的镜像
docker build -t ethereum-etl:2.4.2-transfer .
```

#### 运行导出
```bash
# 使用Docker运行转账交易导出
docker run -v $(pwd)/output:/output ethereum-etl:2.4.2-transfer export_transfer_transactions \
  --start-block 1000000 \
  --end-block 1000100 \
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
  --transfer-transactions-output /output/transfer_transactions.csv
```

### 3. 编程接口使用

#### 直接使用导出器
```python
from ethereumetl.jobs.exporters.transfer_transactions_exporter import TransferTransactionsItemExporter

# 创建导出器
exporter = TransferTransactionsItemExporter(
    transfer_transactions_output='transfer_transactions.csv'
)

# 打开导出器
exporter.open()

# 导出数据
exporter.export_items(transactions)

# 关闭导出器
exporter.close()
```

#### 使用导出任务
```python
from ethereumetl.jobs.export_transfer_transactions_job import ExportTransferTransactionsJob
from ethereumetl.providers.auto import get_provider_from_uri

# 创建导出任务
job = ExportTransferTransactionsJob(
    start_block=1000000,
    end_block=1000100,
    batch_size=100,
    batch_web3_provider=get_provider_from_uri('https://mainnet.infura.io/v3/YOUR_PROJECT_ID', batch=True),
    max_workers=5,
    transfer_transactions_output='transfer_transactions.csv'
)

# 运行任务
job.run()
```

## 输出格式

### CSV格式
转账交易导出为CSV格式，包含以下字段：

| 字段名 | 描述 | 示例 |
|--------|------|------|
| hash | 交易哈希 | 0x1234567890abcdef... |
| nonce | 交易nonce | 0 |
| block_hash | 区块哈希 | 0xabcdef1234567890... |
| block_number | 区块高度 | 1000000 |
| transaction_index | 交易索引 | 0 |
| from_address | 发送地址 | 0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6 |
| to_address | 接收地址 | 0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b7 |
| value | 转账金额（wei） | 1000000000000000000 |
| gas | Gas限制 | 21000 |
| gas_price | Gas价格 | 20000000000 |
| input | 输入数据 | 0x |
| block_timestamp | 区块时间戳 | 1600000000 |
| max_fee_per_gas | 最大Gas费用 | null |
| max_priority_fee_per_gas | 最大优先费用 | null |
| transaction_type | 交易类型 | 0 |
| max_fee_per_blob_gas | 最大Blob Gas费用 | null |
| blob_versioned_hashes | Blob版本哈希 | null |

### 日志输出
- **实时日志**：每个转账交易都会输出区块高度和交易哈希
- **统计日志**：每1000个转账交易输出一次统计信息
- **任务日志**：开始和结束时的任务状态信息

## 测试

### 运行测试脚本
```bash
# 运行单元测试
python test_transfer_exporter.py
```

### 测试输出示例
```
开始测试转账交易导出器...
导出测试数据...
2025-08-29 04:45:12,345 - TransferTransactionConverter - INFO - Transfer Transaction Found - Block: 1000, Hash: 0x1234567890abcdef...
2025-08-29 04:45:12,346 - TransferTransactionConverter - INFO - Transfer Transaction Found - Block: 1001, Hash: 0xabcdef1234567890...
输出文件已创建: /tmp/tmp_xxx.csv
文件内容:
hash,nonce,block_hash,block_number,transaction_index,from_address,to_address,value,gas,gas_price,input,block_timestamp,max_fee_per_gas,max_priority_fee_per_gas,transaction_type,max_fee_per_blob_gas,blob_versioned_hashes
0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef,0,0x00000000000000000000000000000000000000000000000000000000000003e8,1000,0,0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6,0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b7,1000000000000000000,21000,20000000000,0x,1600001000,,,,,,
找到 2 个转账交易记录
记录 1: 确认是转账交易，value = 1000000000000000000
记录 2: 确认是转账交易，value = 500000000000000000
临时文件已清理
```

## 性能优化

### 批量处理
- **批量大小**：建议设置为50-200，根据网络和内存情况调整
- **工作线程**：建议设置为CPU核心数的1-2倍

### 内存优化
- **流式处理**：支持大文件流式处理，避免内存溢出
- **垃圾回收**：自动清理处理过的数据

### 网络优化
- **连接池**：复用HTTP连接，减少网络开销
- **重试机制**：自动重试失败的请求

## 故障排除

### 常见问题

#### 1. 网络连接问题
```bash
# 错误信息
ConnectionError: HTTPSConnectionPool(host='mainnet.infura.io', port=443): Max retries exceeded

# 解决方案
# 检查provider-uri是否正确
# 确保网络连接正常
# 考虑使用本地节点
```

#### 2. 权限问题
```bash
# 错误信息
PermissionError: [Errno 13] Permission denied

# 解决方案
# 确保输出目录有写权限
# 使用sudo或调整目录权限
```

#### 3. 内存不足
```bash
# 错误信息
MemoryError: Unable to allocate array

# 解决方案
# 减少batch-size参数
# 减少max-workers参数
# 增加系统内存
```

### 调试模式
```bash
# 启用详细日志
export PYTHONPATH=.
python -u ethereumetl.py export_transfer_transactions \
  --start-block 1000000 \
  --end-block 1000010 \
  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
  --transfer-transactions-output debug_transfers.csv
```

## 扩展开发

### 添加新的过滤条件
```python
class CustomTransferTransactionConverter:
    def convert_item(self, item):
        if item.get('type') != 'transaction':
            return item
            
        # 添加自定义过滤条件
        value = item.get('value', '0')
        gas_price = item.get('gas_price', '0')
        
        # 例如：只导出大额转账（> 10 ETH）且Gas价格 > 20 Gwei
        if (value and value != '0' and int(value) > 10000000000000000000 and 
            gas_price and int(gas_price) > 20000000000):
            # 输出日志
            self.logger.info(f"Large Transfer Found - Block: {item.get('block_number')}, "
                           f"Hash: {item.get('hash')}, Value: {value}")
        
        return item
```

### 自定义输出格式
```python
class CustomTransferTransactionsItemExporter(TransferTransactionsItemExporter):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # 自定义字段映射
        self.TRANSFER_TRANSACTION_FIELDS_TO_EXPORT = [
            'hash',
            'block_number',
            'from_address',
            'to_address',
            'value',
            'block_timestamp'
        ]
```

## 总结

转账交易导出器提供了：

1. **智能过滤**：自动识别转账交易
2. **实时监控**：通过日志实时查看处理进度
3. **完整数据**：导出转账交易的完整信息
4. **高性能**：支持批量处理和并发处理
5. **易扩展**：模块化设计，易于定制和扩展

该工具特别适用于：
- 区块链数据分析
- 转账行为研究
- 合规性检查
- 交易监控系统 