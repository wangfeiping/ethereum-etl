#!/bin/bash

# 转账交易流式处理状态检查脚本

set -e

# 默认配置
DEFAULT_PID_FILE="transfer_stream.pid"
DEFAULT_LOG_FILE="transfer_stream.log"
DEFAULT_OUTPUT_FILE="transfer_transactions_stream.csv"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印帮助信息
print_help() {
    echo -e "${BLUE}转账交易流式处理状态检查脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --pid-file FILE    PID文件路径 (默认: $DEFAULT_PID_FILE)"
    echo "  --log-file FILE    日志文件路径 (默认: $DEFAULT_LOG_FILE)"
    echo "  --output-file FILE 输出文件路径 (默认: $DEFAULT_OUTPUT_FILE)"
    echo "  --tail LINES       显示日志文件最后N行 (默认: 20)"
    echo "  --follow           实时跟踪日志文件"
    echo "  -h, --help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0"
    echo "  $0 --tail 50"
    echo "  $0 --follow"
    echo ""
}

# 检查进程状态
check_process_status() {
    local pid_file="$1"
    
    if [ ! -f "$pid_file" ]; then
        echo -e "${RED}状态: 未运行 (PID文件不存在)${NC}"
        return 1
    fi
    
    local pid=$(cat "$pid_file")
    
    if ! kill -0 "$pid" 2>/dev/null; then
        echo -e "${RED}状态: 未运行 (进程 $pid 不存在)${NC}"
        rm -f "$pid_file"
        return 1
    fi
    
    echo -e "${GREEN}状态: 运行中 (PID: $pid)${NC}"
    
    # 获取进程详细信息
    if command -v ps &> /dev/null; then
        echo -e "${BLUE}进程信息:${NC}"
        ps -p "$pid" -o pid,ppid,cmd,etime,pcpu,pmem 2>/dev/null || true
    fi
    
    return 0
}

# 检查文件状态
check_file_status() {
    local file="$1"
    local file_type="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}${file_type}: 文件不存在${NC}"
        return 1
    fi
    
    local size=$(du -h "$file" 2>/dev/null | cut -f1 || echo "未知")
    local mtime=$(stat -c %y "$file" 2>/dev/null || echo "未知")
    
    echo -e "${GREEN}${file_type}: 存在${NC}"
    echo "  大小: $size"
    echo "  修改时间: $mtime"
    
    return 0
}

# 显示日志内容
show_log_content() {
    local log_file="$1"
    local tail_lines="$2"
    local follow="$3"
    
    if [ ! -f "$log_file" ]; then
        echo -e "${YELLOW}日志文件不存在: $log_file${NC}"
        return
    fi
    
    echo -e "${BLUE}日志内容 (最后 ${tail_lines} 行):${NC}"
    echo "----------------------------------------"
    
    if [ "$follow" = true ]; then
        tail -f -n "$tail_lines" "$log_file"
    else
        tail -n "$tail_lines" "$log_file"
    fi
}

# 显示输出文件统计
show_output_stats() {
    local output_file="$1"
    
    if [ ! -f "$output_file" ]; then
        echo -e "${YELLOW}输出文件不存在: $output_file${NC}"
        return
    fi
    
    echo -e "${BLUE}输出文件统计:${NC}"
    
    # 计算行数（减去标题行）
    local total_lines=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    local data_lines=$((total_lines - 1))
    
    if [ "$data_lines" -lt 0 ]; then
        data_lines=0
    fi
    
    echo "  总行数: $total_lines"
    echo "  数据行数: $data_lines"
    
    # 如果有数据，显示最后几行
    if [ "$data_lines" -gt 0 ]; then
        echo -e "${BLUE}最后3条记录:${NC}"
        tail -n 3 "$output_file"
    fi
}

# 主函数
main() {
    local pid_file="$DEFAULT_PID_FILE"
    local log_file="$DEFAULT_LOG_FILE"
    local output_file="$DEFAULT_OUTPUT_FILE"
    local tail_lines=20
    local follow=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pid-file)
                pid_file="$2"
                shift 2
                ;;
            --log-file)
                log_file="$2"
                shift 2
                ;;
            --output-file)
                output_file="$2"
                shift 2
                ;;
            --tail)
                tail_lines="$2"
                shift 2
                ;;
            --follow)
                follow=true
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
    
    echo -e "${BLUE}转账交易流式处理状态检查${NC}"
    echo "========================================"
    echo ""
    
    # 检查进程状态
    echo -e "${BLUE}进程状态:${NC}"
    if check_process_status "$pid_file"; then
        echo ""
        
        # 检查文件状态
        echo -e "${BLUE}文件状态:${NC}"
        check_file_status "$pid_file" "PID文件"
        echo ""
        check_file_status "$log_file" "日志文件"
        echo ""
        check_file_status "$output_file" "输出文件"
        echo ""
        
        # 显示输出文件统计
        show_output_stats "$output_file"
        echo ""
        
        # 显示日志内容
        if [ "$follow" = true ]; then
            echo -e "${BLUE}实时日志跟踪 (按 Ctrl+C 退出):${NC}"
            show_log_content "$log_file" "$tail_lines" true
        else
            show_log_content "$log_file" "$tail_lines" false
        fi
    else
        echo ""
        echo -e "${YELLOW}建议: 使用 ./start_transfer_stream.sh 启动流式处理${NC}"
    fi
}

# 运行主函数
main "$@" 