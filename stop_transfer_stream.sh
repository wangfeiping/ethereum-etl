#!/bin/bash

# 转账交易流式处理停止脚本

set -e

# 默认配置
DEFAULT_PID_FILE="transfer_stream.pid"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印帮助信息
print_help() {
    echo -e "${BLUE}转账交易流式处理停止脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --pid-file FILE    PID文件路径 (默认: $DEFAULT_PID_FILE)"
    echo "  --force           强制停止进程"
    echo "  -h, --help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0"
    echo "  $0 --pid-file /var/run/transfer_stream.pid"
    echo "  $0 --force"
    echo ""
}

# 停止进程
stop_process() {
    local pid_file="$1"
    local force="$2"
    
    if [ ! -f "$pid_file" ]; then
        echo -e "${YELLOW}PID文件不存在: $pid_file${NC}"
        return 0
    fi
    
    local pid=$(cat "$pid_file")
    
    if ! kill -0 "$pid" 2>/dev/null; then
        echo -e "${YELLOW}进程 $pid 不存在，删除PID文件${NC}"
        rm -f "$pid_file"
        return 0
    fi
    
    echo -e "${BLUE}停止进程 $pid...${NC}"
    
    if [ "$force" = true ]; then
        echo -e "${YELLOW}强制停止进程...${NC}"
        kill -9 "$pid"
    else
        kill "$pid"
        
        # 等待进程正常退出
        local count=0
        while kill -0 "$pid" 2>/dev/null && [ $count -lt 30 ]; do
            echo -e "${BLUE}等待进程退出... ($((30-count))秒)${NC}"
            sleep 1
            count=$((count + 1))
        done
        
        # 如果进程仍在运行，强制停止
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}进程未在30秒内退出，强制停止${NC}"
            kill -9 "$pid"
        fi
    fi
    
    # 验证进程是否已停止
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${RED}无法停止进程 $pid${NC}"
        return 1
    else
        echo -e "${GREEN}进程 $pid 已停止${NC}"
        rm -f "$pid_file"
        return 0
    fi
}

# 主函数
main() {
    local pid_file="$DEFAULT_PID_FILE"
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pid-file)
                pid_file="$2"
                shift 2
                ;;
            --force)
                force=true
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
    
    echo -e "${BLUE}停止转账交易流式处理...${NC}"
    echo "PID文件: $pid_file"
    echo "强制停止: $force"
    echo ""
    
    if stop_process "$pid_file" "$force"; then
        echo -e "${GREEN}转账交易流式处理已停止${NC}"
    else
        echo -e "${RED}停止转账交易流式处理失败${NC}"
        exit 1
    fi
}

# 运行主函数
main "$@" 