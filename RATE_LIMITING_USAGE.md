# Request Rate Limiting for export_transfer_transactions

This document describes the new `--request-per-second` parameter added to the `export_transfer_transactions` command to control RPC call frequency.

## Overview

The `--request-per-second` parameter allows you to limit the rate of RPC calls made to the Ethereum node, which can help:

- Avoid overwhelming RPC endpoints with too many requests
- Comply with rate limits imposed by RPC providers
- Reduce the load on your own Ethereum node
- Prevent hitting API quotas too quickly

## Usage

### Basic Usage

```bash
# Limit to 5 requests per second
python3 -m ethereumetl export_transfer_transactions \
    --start-block 18000000 \
    --end-block 18000010 \
    --provider-uri https://mainnet.infura.io/v3/your-project-id \
    --request-per-second 5.0 \
    --transfer-transactions-output transfers.csv

# Limit to 0.5 requests per second (one request every 2 seconds)
python3 -m ethereumetl export_transfer_transactions \
    --start-block 18000000 \
    --end-block 18000010 \
    --provider-uri https://mainnet.infura.io/v3/your-project-id \
    --request-per-second 0.5 \
    --transfer-transactions-output transfers.csv
```

### Without Rate Limiting (Default)

```bash
# No rate limiting - maximum speed
python3 -m ethereumetl export_transfer_transactions \
    --start-block 18000000 \
    --end-block 18000010 \
    --provider-uri https://mainnet.infura.io/v3/your-project-id \
    --transfer-transactions-output transfers.csv
```

## Parameter Details

- **Parameter**: `--request-per-second`
- **Type**: Float
- **Default**: `None` (no rate limiting)
- **Description**: Maximum number of RPC requests per second
- **Examples**:
  - `10.0` = 10 requests per second
  - `1.0` = 1 request per second  
  - `0.5` = 1 request every 2 seconds
  - `0.1` = 1 request every 10 seconds

## Implementation Details

### How It Works

1. **Rate Limiting Class**: A new `RateLimitedBatchWorkExecutor` class extends the existing `BatchWorkExecutor`
2. **Timing Control**: Before each batch execution, the system calculates the minimum interval between requests
3. **Sleep Mechanism**: If insufficient time has passed since the last request, the system sleeps for the required duration
4. **Automatic Selection**: The system automatically chooses between rate-limited and standard executors based on the parameter

### Code Changes Made

1. **CLI Parameter**: Added `--request-per-second` option to the command line interface
2. **Job Class**: Modified `ExportTransferTransactionsJob` to accept and use the rate limiting parameter
3. **Executor**: Created `RateLimitedBatchWorkExecutor` with built-in rate limiting functionality

### Logging

When rate limiting is enabled, you'll see a log message like:
```
Rate limiting enabled: 5.0 requests per second
```

## Recommendations

### For Public RPC Providers

- **Infura**: Start with 10-50 requests per second depending on your plan
- **Alchemy**: Check your plan's rate limits and set accordingly
- **QuickNode**: Typically allows 25-500 requests per second depending on plan

### For Local Nodes

- **Geth/Erigon**: Can typically handle 100+ requests per second
- **Monitor resource usage** and adjust based on node performance

### General Guidelines

1. **Start Conservative**: Begin with lower rates (1-5 rps) and increase as needed
2. **Monitor Logs**: Watch for rate limiting errors from your provider
3. **Balance Speed vs. Stability**: Higher rates = faster execution but more likely to hit limits
4. **Consider Batch Size**: Larger batch sizes with lower request rates can be more efficient

## Error Handling

The rate limiting system works with the existing retry mechanism. If requests fail due to rate limiting by the provider, the system will:

1. Automatically retry failed requests
2. Reduce batch sizes if needed
3. Continue with exponential backoff as before

## Performance Impact

- **Overhead**: Minimal computational overhead per request
- **Memory**: No additional memory usage
- **Timing Accuracy**: Uses `time.sleep()` for millisecond-level precision

