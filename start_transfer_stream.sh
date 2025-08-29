#!/bin/bash

# 转账交易流式处理启动脚本
# 持续监控新区块并导出转账交易

set -e

# 默认配置
DEFAULT_PROVIDER_URI="https://mainnet.infura.io"
DEFAULT_START_BLOCK=""
DEFAULT_PERIOD_SECONDS=10
DEFAULT_BATCH_SIZE=100
DEFAULT_MAX_WORKERS=5
DEFAULT_LAG=0
DEFAULT_OUTPUT_FILE="transfer_transactions_stream.csv"
DEFAULT_LOG_FILE="transfer_stream.log"
DEFAULT_PID_FILE="transfer_stream.pid"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印帮助信息
print_help() {
    echo -e "${BLUE}转账交易流式处理启动脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -p, --provider-uri URI      Web3提供者URI (默认: $DEFAULT_PROVIDER_URI)"
    echo "  -s, --start-block BLOCK     开始区块号 (默认: 从最新区块开始)"
    echo "  -t, --period-seconds SEC    同步间隔秒数 (默认: $DEFAULT_PERIOD_SECONDS)"
    echo "  -b, --batch-size SIZE       批量大小 (默认: $DEFAULT_BATCH_SIZE)"
    echo "  -w, --max-workers WORKERS   最大工作线程数 (默认: $DEFAULT_MAX_WORKERS)"
    echo "  -l, --lag LAG               滞后区块数 (默认: $DEFAULT_LAG)"
    echo "  -o, --output FILE           输出文件 (默认: $DEFAULT_OUTPUT_FILE)"
    echo "  --log-file FILE             日志文件 (默认: $DEFAULT_LOG_FILE)"
    echo "  --pid-file FILE             PID文件 (默认: $DEFAULT_PID_FILE)"
    echo "  --export-blocks             同时导出区块数据"
    echo "  --no-export-transactions    不导出交易数据"
    echo "  -d, --daemon                以守护进程模式运行"
    echo "  -h, --help                  显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -p https://mainnet.infura.io -s 18000000"
    echo "  $0 --daemon --log-file /var/log/transfer_stream.log"
    echo ""
}

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}检查依赖...${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}错误: 未找到 python3${NC}"
        exit 1
    fi
    
    if ! python3 -c "import ethereumetl" &> /dev/null; then
        echo -e "${RED}错误: 未找到 ethereumetl 模块${NC}"
        echo "请确保已安装 ethereum-etl: pip install ethereum-etl"
        exit 1
    fi
    
    echo -e "${GREEN}依赖检查通过${NC}"
}

# 停止现有进程
stop_existing_process() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo -e "${YELLOW}停止现有进程 (PID: $PID)...${NC}"
            kill "$PID"
            sleep 2
            if kill -0 "$PID" 2>/dev/null; then
                echo -e "${YELLOW}强制停止进程...${NC}"
                kill -9 "$PID"
            fi
        fi
        rm -f "$PID_FILE"
    fi
}

# 启动流式处理
start_streaming() {
    echo -e "${BLUE}启动转账交易流式处理...${NC}"
    
    # 构建命令
    CMD="python3 ethereumetl/cli/stream_transfer_transactions.py"
    CMD="$CMD --provider-uri '$PROVIDER_URI'"
    CMD="$CMD --transfer-transactions-output '$OUTPUT_FILE'"
    CMD="$CMD --period-seconds $PERIOD_SECONDS"
    CMD="$CMD --batch-size $BATCH_SIZE"
    CMD="$CMD --max-workers $MAX_WORKERS"
    CMD="$CMD --lag $LAG"
    CMD="$CMD --log-file '$LOG_FILE'"
    CMD="$CMD --pid-file '$PID_FILE'"
    
    if [ -n "$START_BLOCK" ]; then
        CMD="$CMD --start-block $START_BLOCK"
    fi
    
    if [ "$EXPORT_BLOCKS" = true ]; then
        CMD="$CMD --export-blocks"
    fi
    
    if [ "$EXPORT_TRANSACTIONS" = false ]; then
        CMD="$CMD --no-export-transactions"
    fi
    
    echo -e "${BLUE}执行命令: $CMD${NC}"
    
    if [ "$DAEMON_MODE" = true ]; then
        # 守护进程模式
        nohup $CMD > /dev/null 2>&1 &
        echo -e "${GREEN}流式处理已在后台启动${NC}"
        echo -e "${BLUE}日志文件: $LOG_FILE${NC}"
        echo -e "${BLUE}PID文件: $PID_FILE${NC}"
    else
        # 前台模式
        exec $CMD
    fi
}

# 主函数
main() {
    # 解析命令行参数
    PROVIDER_URI="$DEFAULT_PROVIDER_URI"
    START_BLOCK="$DEFAULT_START_BLOCK"
    PERIOD_SECONDS="$DEFAULT_PERIOD_SECONDS"
    BATCH_SIZE="$DEFAULT_BATCH_SIZE"
    MAX_WORKERS="$DEFAULT_MAX_WORKERS"
    LAG="$DEFAULT_LAG"
    OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"
    LOG_FILE="$DEFAULT_LOG_FILE"
    PID_FILE="$DEFAULT_PID_FILE"
    EXPORT_BLOCKS=false
    EXPORT_TRANSACTIONS=true
    DAEMON_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--provider-uri)
                PROVIDER_URI="$2"
                shift 2
                ;;
            -s|--start-block)
                START_BLOCK="$2"
                shift 2
                ;;
            -t|--period-seconds)
                PERIOD_SECONDS="$2"
                shift 2
                ;;
            -b|--batch-size)
                BATCH_SIZE="$2"
                shift 2
                ;;
            -w|--max-workers)
                MAX_WORKERS="$2"
                shift 2
                ;;
            -l|--lag)
                LAG="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            --pid-file)
                PID_FILE="$2"
                shift 2
                ;;
            --export-blocks)
                EXPORT_BLOCKS=true
                shift
                ;;
            --no-export-transactions)
                EXPORT_TRANSACTIONS=false
                shift
                ;;
            -d|--daemon)
                DAEMON_MODE=true
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                print_help
                exit 1
                ;;
        esac
    done
    
    # 显示配置
    echo -e "${BLUE}配置信息:${NC}"
    echo "  提供者URI: $PROVIDER_URI"
    echo "  开始区块: ${START_BLOCK:-'最新区块'}"
    echo "  同步间隔: ${PERIOD_SECONDS}秒"
    echo "  批量大小: $BATCH_SIZE"
    echo "  最大工作线程: $MAX_WORKERS"
    echo "  滞后区块数: $LAG"
    echo "  输出文件: $OUTPUT_FILE"
    echo "  日志文件: $LOG_FILE"
    echo "  PID文件: $PID_FILE"
    echo "  导出区块: $EXPORT_BLOCKS"
    echo "  导出交易: $EXPORT_TRANSACTIONS"
    echo "  守护进程模式: $DAEMON_MODE"
    echo ""
    
    # 检查依赖
    check_dependencies
    
    # 停止现有进程
    stop_existing_process
    
    # 启动流式处理
    start_streaming
}

# 运行主函数
main "$@" 