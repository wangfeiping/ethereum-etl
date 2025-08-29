#!/bin/bash

# 支持配置文件的转账交易流式处理启动脚本

set -e

# 默认配置
DEFAULT_CONFIG_FILE="transfer_stream_config.json"
DEFAULT_ENVIRONMENT="development"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印帮助信息
print_help() {
    echo -e "${BLUE}配置化转账交易流式处理启动脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -c, --config FILE    配置文件路径 (默认: $DEFAULT_CONFIG_FILE)"
    echo "  -e, --env ENV        环境名称 (默认: $DEFAULT_ENVIRONMENT)"
    echo "  -h, --help           显示此帮助信息"
    echo ""
    echo "环境选项:"
    echo "  development         开发环境配置"
    echo "  testing            测试环境配置"
    echo "  production         生产环境配置"
    echo "  high_performance   高性能配置"
    echo "  database_output    数据库输出配置"
    echo "  kafka_output       Kafka输出配置"
    echo ""
    echo "示例:"
    echo "  $0 -e production"
    echo "  $0 -c my_config.json -e testing"
    echo ""
}

# 检查JSON工具
check_json_tools() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}错误: 未找到 jq 工具${NC}"
        echo "请安装 jq: sudo apt-get install jq 或 sudo yum install jq"
        exit 1
    fi
}

# 读取配置
read_config() {
    local config_file="$1"
    local environment="$2"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}错误: 配置文件不存在: $config_file${NC}"
        exit 1
    fi
    
    # 检查环境是否存在
    if ! jq -e ".$environment" "$config_file" > /dev/null 2>&1; then
        echo -e "${RED}错误: 环境 '$environment' 在配置文件中不存在${NC}"
        echo "可用环境:"
        jq -r 'keys[]' "$config_file"
        exit 1
    fi
    
    # 读取配置
    local provider_uri=$(jq -r ".$environment.provider_uri" "$config_file")
    local start_block=$(jq -r ".$environment.start_block" "$config_file")
    local period_seconds=$(jq -r ".$environment.period_seconds" "$config_file")
    local batch_size=$(jq -r ".$environment.batch_size" "$config_file")
    local max_workers=$(jq -r ".$environment.max_workers" "$config_file")
    local lag=$(jq -r ".$environment.lag" "$config_file")
    local output_file=$(jq -r ".$environment.output_file" "$config_file")
    local log_file=$(jq -r ".$environment.log_file" "$config_file")
    local pid_file=$(jq -r ".$environment.pid_file" "$config_file")
    local export_blocks=$(jq -r ".$environment.export_blocks" "$config_file")
    local export_transactions=$(jq -r ".$environment.export_transactions" "$config_file")
    local daemon_mode=$(jq -r ".$environment.daemon_mode" "$config_file")
    
    # 处理null值
    [ "$start_block" = "null" ] && start_block=""
    
    # 构建启动命令
    local cmd="./start_transfer_stream.sh"
    cmd="$cmd --provider-uri '$provider_uri'"
    cmd="$cmd --transfer-transactions-output '$output_file'"
    cmd="$cmd --period-seconds $period_seconds"
    cmd="$cmd --batch-size $batch_size"
    cmd="$cmd --max-workers $max_workers"
    cmd="$cmd --lag $lag"
    cmd="$cmd --log-file '$log_file'"
    cmd="$cmd --pid-file '$pid_file'"
    
    if [ -n "$start_block" ]; then
        cmd="$cmd --start-block $start_block"
    fi
    
    if [ "$export_blocks" = "true" ]; then
        cmd="$cmd --export-blocks"
    fi
    
    if [ "$export_transactions" = "false" ]; then
        cmd="$cmd --no-export-transactions"
    fi
    
    if [ "$daemon_mode" = "true" ]; then
        cmd="$cmd --daemon"
    fi
    
    echo "$cmd"
}

# 显示配置信息
show_config() {
    local config_file="$1"
    local environment="$2"
    
    echo -e "${BLUE}配置信息:${NC}"
    echo "  配置文件: $config_file"
    echo "  环境: $environment"
    echo ""
    
    echo -e "${BLUE}参数详情:${NC}"
    jq -r ".$environment | to_entries[] | \"  \(.key): \(.value)\"" "$config_file"
    echo ""
}

# 主函数
main() {
    local config_file="$DEFAULT_CONFIG_FILE"
    local environment="$DEFAULT_ENVIRONMENT"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            -e|--env)
                environment="$2"
                shift 2
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
    
    echo -e "${BLUE}配置化转账交易流式处理启动${NC}"
    echo "========================================"
    echo ""
    
    # 检查JSON工具
    check_json_tools
    
    # 显示配置信息
    show_config "$config_file" "$environment"
    
    # 读取配置并构建命令
    local cmd=$(read_config "$config_file" "$environment")
    
    echo -e "${BLUE}执行命令:${NC}"
    echo "$cmd"
    echo ""
    
    # 确认执行
    read -p "是否继续执行？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}用户取消执行${NC}"
        exit 0
    fi
    
    # 执行命令
    echo -e "${BLUE}开始执行...${NC}"
    eval "$cmd"
}

# 运行主函数
main "$@" 