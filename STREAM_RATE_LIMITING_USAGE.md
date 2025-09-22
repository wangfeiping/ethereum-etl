# Request Rate Limiting for stream_transfer_transactions

This document describes the new `--request-per-second` parameter added to the `stream_transfer_transactions` command to control RPC call frequency during continuous streaming.

## Overview

The `--request-per-second` parameter allows you to limit the rate of RPC calls made to the Ethereum node during continuous streaming, which can help:

- Avoid overwhelming RPC endpoints with too many requests during continuous operation
- Comply with rate limits imposed by RPC providers for long-running processes
- Reduce the load on your own Ethereum node during streaming
- Prevent hitting API quotas too quickly during continuous monitoring
- Maintain stable performance over extended periods

## Usage

### Basic Usage

```bash
# Stream with 5 requests per second rate limiting
python3 -m ethereumetl stream_transfer_transactions \
    --provider-uri https://mainnet.infura.io/v3/your-project-id \
    --request-per-second 5.0 \
    --transfer-transactions-output transfers_stream.csv \
    --period-seconds 10

# Stream with 0.5 requests per second (one request every 2 seconds)
python3 -m ethereumetl stream_transfer_transactions \
    --provider-uri https://mainnet.infura.io/v3/your-project-id \
    --request-per-second 0.5 \
    --transfer-transactions-output transfers_stream.csv \
    --period-seconds 30

# Stream with rate limiting and custom start block
python3 -m ethereumetl stream_transfer_transactions \
    --provider-uri https://mainnet.infura.io/v3/your-project-id \
    --request-per-second 10.0 \
    --start-block 18000000 \
    --transfer-transactions-output transfers_stream.csv \
    --period-seconds 5
```

### Without Rate Limiting (Default)

```bash
# No rate limiting - maximum speed
python3 -m ethereumetl stream_transfer_transactions \
    --provider-uri https://mainnet.infura.io/v3/your-project-id \
    --transfer-transactions-output transfers_stream.csv \
    --period-seconds 10
```

### Advanced Usage with Other Parameters

```bash
# Complete example with all parameters
python3 -m ethereumetl stream_transfer_transactions \
    --provider-uri https://mainnet.infura.io/v3/your-project-id \
    --request-per-second 8.0 \
    --transfer-transactions-output transfers_stream.csv \
    --last-synced-block-file last_sync.txt \
    --lag 2 \
    --start-block 18000000 \
    --period-seconds 15 \
    --batch-size 50 \
    --max-workers 3 \
    --export-transactions \
    --log-file stream.log \
    --pid-file stream.pid \
    --prometheus-port 8001 \
    --log-level INFO
```

## Parameter Details

- **Parameter**: `--request-per-second`
- **Type**: Float
- **Default**: `None` (no rate limiting)
- **Description**: Maximum number of RPC requests per second during streaming
- **Examples**:
  - `10.0` = 10 requests per second
  - `1.0` = 1 request per second  
  - `0.5` = 1 request every 2 seconds
  - `0.1` = 1 request every 10 seconds

## Implementation Details

### How It Works

1. **Streaming Integration**: The `TransferTransactionStreamer` class now accepts the `request_per_second` parameter
2. **Job Delegation**: The parameter is passed to each `ExportTransferTransactionsJob` instance created during streaming
3. **Rate Limiting**: Each job uses the `RateLimitedBatchWorkExecutor` when rate limiting is enabled
4. **Continuous Operation**: Rate limiting applies to all RPC calls made during the continuous streaming process

### Code Changes Made

1. **CLI Parameter**: Added `--request-per-second` option to the stream command
2. **Streamer Class**: Modified `TransferTransactionStreamer` to accept and store the rate limiting parameter
3. **Job Integration**: Updated job instantiation to pass the rate limiting parameter
4. **Parameter Flow**: Ensured the parameter flows from CLI → Streamer → Job → Executor

### Logging

When rate limiting is enabled during streaming, you'll see log messages like:
```
Rate limiting enabled: 5.0 requests per second
```

## Streaming-Specific Considerations

### Period vs Rate Limiting

- **`--period-seconds`**: Controls how often the streamer checks for new blocks
- **`--request-per-second`**: Controls how fast RPC calls are made within each check
- These parameters work together to provide fine-grained control over streaming performance

### Batch Size Interaction

- Larger `--batch-size` values with lower `--request-per-second` can be more efficient
- The rate limiting applies to the entire batch request, not individual blocks
- Consider your RPC provider's batch request limits when setting these parameters

### Long-Running Operations

- Rate limiting is especially important for long-running streaming operations
- Helps maintain stable performance over hours or days of continuous operation
- Prevents temporary network issues from causing cascading failures

## Recommendations

### For Continuous Streaming

- **Conservative Start**: Begin with 5-10 requests per second for continuous operation
- **Monitor Performance**: Watch for rate limiting errors and adjust accordingly
- **Balance Parameters**: Consider the relationship between `--period-seconds`, `--batch-size`, and `--request-per-second`

### For Different RPC Providers

- **Infura**: 10-50 requests per second depending on your plan
- **Alchemy**: Check your plan's rate limits and set accordingly
- **QuickNode**: Typically allows 25-500 requests per second depending on plan
- **Local Nodes**: Can typically handle 100+ requests per second

### Error Handling

The streaming system includes robust error handling:

1. **Automatic Retries**: Failed requests are automatically retried
2. **Batch Size Reduction**: Batch sizes are reduced if requests fail
3. **Exponential Backoff**: Built-in backoff mechanisms for temporary failures
4. **Continuous Operation**: The streamer continues running even if individual batches fail

## Performance Impact

- **Overhead**: Minimal computational overhead per request
- **Memory**: No additional memory usage
- **Timing Accuracy**: Uses `time.sleep()` for millisecond-level precision
- **Streaming Stability**: Helps maintain stable performance over long periods

## Monitoring

The streamer includes Prometheus metrics for monitoring:

- `ethereum_etl_synced_height`: Current sync height
- `ethereum_etl_blocks_processed_total`: Total blocks processed
- `ethereum_etl_processing_duration_seconds`: Processing time per operation
- `ethereum_etl_errors_total`: Error counts by type

Access metrics at: `http://localhost:8000/metrics` (or your configured port)

## Example Scenarios

### Scenario 1: Conservative Streaming
```bash
# Safe for most RPC providers
--request-per-second 5.0 --period-seconds 30 --batch-size 20
```

### Scenario 2: High-Performance Local Node
```bash
# For local nodes with high capacity
--request-per-second 50.0 --period-seconds 5 --batch-size 100
```

### Scenario 3: Catching Up from Behind
```bash
# When you need to catch up quickly but still respect limits
--request-per-second 20.0 --period-seconds 10 --batch-size 50
```

### Scenario 4: Minimal Resource Usage
```bash
# For resource-constrained environments
--request-per-second 1.0 --period-seconds 60 --batch-size 10
```

