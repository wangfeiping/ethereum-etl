# Prometheus 集成说明

## 概述

`ethereumetl/cli/stream_transfer_transactions.py` 现已集成 Prometheus exporter，提供实时的监控指标，特别是 `synced_height` 指标来跟踪已完成解析的区块高度。

## 功能特性

### 🎯 核心指标

1. **`ethereum_etl_synced_height`** - 已完成解析的区块高度
   - 类型: Gauge
   - 标签: `network`, `provider`
   - 说明: 实时显示当前已同步到的最新区块高度

2. **`ethereum_etl_blocks_processed_total`** - 已处理的区块总数
   - 类型: Counter
   - 标签: `network`, `provider`
   - 说明: 累计处理的区块数量

3. **`ethereum_etl_transactions_processed_total`** - 已处理的交易总数
   - 类型: Counter
   - 标签: `network`, `provider`
   - 说明: 累计处理的交易数量

4. **`ethereum_etl_transfer_transactions_total`** - 已处理的转账交易总数
   - 类型: Counter
   - 标签: `network`, `provider`
   - 说明: 累计处理的转账交易数量

5. **`ethereum_etl_processing_duration_seconds`** - 处理时间
   - 类型: Histogram
   - 标签: `network`, `provider`, `operation`
   - 说明: 处理操作的耗时分布

6. **`ethereum_etl_errors_total`** - 错误总数
   - 类型: Counter
   - 标签: `network`, `provider`, `error_type`
   - 说明: 累计错误数量

7. **`ethereum_etl_app_info`** - 应用信息
   - 类型: Info
   - 说明: 应用版本和组件信息

## 安装依赖

### 方法1：使用 pip 安装

```bash
pip install prometheus_client>=0.12.0
```

### 方法2：使用项目依赖

```bash
pip install -e .[streaming]
```

## 使用方法

### 基本使用

```bash
python ethereumetl/cli/stream_transfer_transactions.py \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output transfers.csv \
    --prometheus-port 8000
```

### 完整参数示例

```bash
python ethereumetl/cli/stream_transfer_transactions.py \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /data/transfers.csv \
    --period-seconds 10 \
    --batch-size 100 \
    --max-workers 5 \
    --prometheus-port 8000 \
    --log-file /logs/stream.log \
    --pid-file /state/stream.pid
```

### Docker 中使用

```bash
docker run -it \
    -p 8000:8000 \
    -v $(pwd)/data:/app/data \
    -v $(pwd)/logs:/app/logs \
    -v $(pwd)/state:/app/state \
    ethereum-etl-transfer-stream:latest \
    python ethereumetl/cli/stream_transfer_transactions.py \
    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \
    --transfer-transactions-output /app/data/transfers.csv \
    --prometheus-port 8000
```

## 访问指标

### 1. 直接访问

```bash
# 获取所有指标
curl http://localhost:8000/metrics

# 获取特定指标
curl http://localhost:8000/metrics | grep ethereum_etl_synced_height
```

### 2. 浏览器访问

在浏览器中打开: `http://localhost:8000/metrics`

### 3. 指标示例

```
# HELP ethereum_etl_synced_height 已完成解析的区块高度
# TYPE ethereum_etl_synced_height gauge
ethereum_etl_synced_height{network="mainnet",provider="infura"} 18500000

# HELP ethereum_etl_blocks_processed_total 已处理的区块总数
# TYPE ethereum_etl_blocks_processed_total counter
ethereum_etl_blocks_processed_total{network="mainnet",provider="infura"} 1000

# HELP ethereum_etl_transfer_transactions_total 已处理的转账交易总数
# TYPE ethereum_etl_transfer_transactions_total counter
ethereum_etl_transfer_transactions_total{network="mainnet",provider="infura"} 5000
```

## 网络和提供者标签

系统会自动从 `provider_uri` 中提取网络和提供者信息：

### 支持的网络
- `mainnet` - 以太坊主网
- `goerli` - Goerli 测试网
- `sepolia` - Sepolia 测试网
- `polygon` - Polygon 网络
- `bsc` - BSC 网络

### 支持的提供者
- `infura` - Infura
- `alchemy` - Alchemy
- `quicknode` - QuickNode
- `local` - 本地节点

## 监控配置

### 1. Prometheus 配置

在 `prometheus.yml` 中添加：

```yaml
scrape_configs:
  - job_name: 'ethereum-etl'
    static_configs:
      - targets: ['localhost:8000']
    scrape_interval: 15s
    metrics_path: /metrics
```

### 2. Grafana 仪表板

创建 Grafana 仪表板，包含以下面板：

#### 同步进度面板
```
# 查询
ethereum_etl_synced_height{network="mainnet"}

# 显示
- 当前同步高度
- 同步速度（导数）
- 与最新区块的差距
```

#### 处理性能面板
```
# 查询
rate(ethereum_etl_blocks_processed_total[5m])
rate(ethereum_etl_transfer_transactions_total[5m])

# 显示
- 区块处理速率
- 转账交易处理速率
- 处理时间分布
```

#### 错误监控面板
```
# 查询
rate(ethereum_etl_errors_total[5m])

# 显示
- 错误率
- 错误类型分布
```

### 3. 告警规则

在 Prometheus 中配置告警：

```yaml
groups:
  - name: ethereum-etl
    rules:
      - alert: SyncLagTooHigh
        expr: (ethereum_etl_synced_height - ethereum_etl_synced_height offset 5m) < 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "同步延迟过高"
          description: "5分钟内同步的区块数少于10个"

      - alert: ProcessingErrors
        expr: rate(ethereum_etl_errors_total[5m]) > 0.1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "处理错误率过高"
          description: "错误率超过0.1/秒"
```

## 测试

### 运行测试脚本

```bash
python test_prometheus_integration.py
```

### 手动测试

```bash
# 1. 启动流式处理器
python ethereumetl/cli/stream_transfer_transactions.py \
    --provider-uri https://goerli.infura.io/v3/YOUR_PROJECT_ID \
    --prometheus-port 8000 \
    --period-seconds 5 \
    --batch-size 10

# 2. 在另一个终端检查指标
curl http://localhost:8000/metrics | grep ethereum_etl_synced_height

# 3. 监控指标变化
watch -n 5 'curl -s http://localhost:8000/metrics | grep ethereum_etl_synced_height'
```

## 故障排除

### 1. 指标服务器无法启动

```bash
# 检查端口是否被占用
netstat -tlnp | grep 8000

# 检查防火墙设置
sudo ufw status
```

### 2. 指标不更新

```bash
# 检查日志
tail -f /logs/stream.log | grep -i prometheus

# 检查网络连接
curl -v http://localhost:8000/metrics
```

### 3. 依赖问题

```bash
# 重新安装依赖
pip uninstall prometheus_client
pip install prometheus_client>=0.12.0

# 检查安装
python -c "import prometheus_client; print('OK')"
```

## 性能考虑

### 1. 指标更新频率
- 同步高度指标在每次区块同步后更新
- 其他指标在处理完成后更新
- 建议监控间隔：15-30秒

### 2. 内存使用
- Prometheus 客户端使用少量内存
- 指标存储在内存中，不会持久化
- 重启后指标会重置

### 3. 网络开销
- 指标服务器使用 HTTP 协议
- 每次请求返回所有指标
- 建议使用本地网络访问

## 扩展功能

### 1. 自定义指标

可以在代码中添加更多指标：

```python
# 添加自定义指标
self.custom_metric = Gauge(
    'ethereum_etl_custom_metric',
    '自定义指标描述',
    ['label1', 'label2']
)

# 更新指标
self.custom_metric.labels(label1='value1', label2='value2').set(42)
```

### 2. 指标持久化

可以添加指标持久化功能：

```python
# 保存指标到文件
from prometheus_client import write_to_textfile
write_to_textfile('/tmp/metrics.prom', REGISTRY)
```

### 3. 多实例监控

支持多个流式处理器实例的监控：

```yaml
# Prometheus 配置
scrape_configs:
  - job_name: 'ethereum-etl'
    static_configs:
      - targets: ['instance1:8000', 'instance2:8000', 'instance3:8000']
```

## 总结

Prometheus 集成提供了：

1. ✅ **实时监控** - 同步高度和处理进度
2. ✅ **性能指标** - 处理速度和耗时
3. ✅ **错误监控** - 错误率和类型
4. ✅ **多网络支持** - 自动识别网络和提供者
5. ✅ **易于集成** - 标准 Prometheus 格式
6. ✅ **可扩展性** - 支持自定义指标

通过这些指标，您可以全面监控以太坊 ETL 流式处理器的运行状态和性能。 