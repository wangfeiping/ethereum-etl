#!/bin/bash

# Docker 转账交易流式处理启动脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_COMPOSE_FILE="docker-compose.transfer-stream.yml"
DEFAULT_ENV_FILE=".env"

# 打印帮助信息
print_help() {
    echo -e "${BLUE}Docker 转账交易流式处理启动脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -f, --compose-file FILE  Docker Compose文件 (默认: $DEFAULT_COMPOSE_FILE)"
    echo "  -e, --env-file FILE      环境变量文件 (默认: $DEFAULT_ENV_FILE)"
    echo "  -s, --start              启动服务"
    echo "  -S, --stop               停止服务"
    echo "  -r, --restart            重启服务"
    echo "  -l, --logs               查看日志"
    echo "  -m, --monitor            启动监控"
    echo "  -c, --clean              清理容器和数据"
    echo "  -h, --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -s                    # 启动服务"
    echo "  $0 -s -m                 # 启动服务和监控"
    echo "  $0 -l                    # 查看日志"
    echo "  $0 -S                    # 停止服务"
    echo ""
}

# 检查Docker和Docker Compose
check_docker() {
    echo -e "${BLUE}检查Docker环境...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: 未找到 Docker${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}错误: 未找到 Docker Compose${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}错误: Docker 服务未运行${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Docker 环境检查通过${NC}"
}

# 创建必要的目录
create_directories() {
    echo -e "${BLUE}创建必要的目录...${NC}"
    
    mkdir -p data logs state config
    
    echo -e "${GREEN}目录创建完成${NC}"
}

# 检查环境变量文件
check_env_file() {
    local env_file="$1"
    
    if [ ! -f "$env_file" ]; then
        echo -e "${YELLOW}环境变量文件不存在: $env_file${NC}"
        echo -e "${BLUE}创建默认环境变量文件...${NC}"
        cp env.example "$env_file"
        echo -e "${YELLOW}请编辑 $env_file 文件，配置您的参数${NC}"
        echo -e "${YELLOW}特别是 PROVIDER_URI 需要设置为您的 Infura 项目ID${NC}"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# 启动服务
start_services() {
    local compose_file="$1"
    local env_file="$2"
    local monitor="$3"
    
    echo -e "${BLUE}启动转账交易流式处理服务...${NC}"
    
    # 构建服务
    echo -e "${BLUE}构建Docker镜像...${NC}"
    docker-compose -f "$compose_file" --env-file "$env_file" build
    
    # 启动主服务
    echo -e "${BLUE}启动主服务...${NC}"
    docker-compose -f "$compose_file" --env-file "$env_file" up -d transfer-stream
    
    # 等待服务启动
    echo -e "${BLUE}等待服务启动...${NC}"
    sleep 10
    
    # 检查服务状态
    if docker-compose -f "$compose_file" --env-file "$env_file" ps transfer-stream | grep -q "Up"; then
        echo -e "${GREEN}主服务启动成功${NC}"
    else
        echo -e "${RED}主服务启动失败${NC}"
        docker-compose -f "$compose_file" --env-file "$env_file" logs transfer-stream
        exit 1
    fi
    
    # 启动监控服务（如果请求）
    if [ "$monitor" = true ]; then
        echo -e "${BLUE}启动监控服务...${NC}"
        docker-compose -f "$compose_file" --env-file "$env_file" up -d transfer-stream-monitor transfer-stream-logs
        echo -e "${GREEN}监控服务启动成功${NC}"
    fi
    
    echo -e "${GREEN}所有服务启动完成${NC}"
}

# 停止服务
stop_services() {
    local compose_file="$1"
    local env_file="$2"
    
    echo -e "${BLUE}停止转账交易流式处理服务...${NC}"
    docker-compose -f "$compose_file" --env-file "$env_file" down
    echo -e "${GREEN}服务已停止${NC}"
}

# 重启服务
restart_services() {
    local compose_file="$1"
    local env_file="$2"
    
    echo -e "${BLUE}重启转账交易流式处理服务...${NC}"
    docker-compose -f "$compose_file" --env-file "$env_file" restart
    echo -e "${GREEN}服务已重启${NC}"
}

# 查看日志
show_logs() {
    local compose_file="$1"
    local env_file="$2"
    
    echo -e "${BLUE}显示转账交易流式处理日志...${NC}"
    docker-compose -f "$compose_file" --env-file "$env_file" logs -f transfer-stream
}

# 清理服务
clean_services() {
    local compose_file="$1"
    local env_file="$2"
    
    echo -e "${YELLOW}警告: 这将删除所有容器和数据${NC}"
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}操作已取消${NC}"
        exit 0
    fi
    
    echo -e "${BLUE}清理转账交易流式处理服务...${NC}"
    docker-compose -f "$compose_file" --env-file "$env_file" down -v
    docker system prune -f
    echo -e "${GREEN}清理完成${NC}"
}

# 显示服务状态
show_status() {
    local compose_file="$1"
    local env_file="$2"
    
    echo -e "${BLUE}转账交易流式处理服务状态:${NC}"
    docker-compose -f "$compose_file" --env-file "$env_file" ps
    
    echo -e "${BLUE}容器资源使用情况:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# 主函数
main() {
    local compose_file="$DEFAULT_COMPOSE_FILE"
    local env_file="$DEFAULT_ENV_FILE"
    local action=""
    local monitor=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--compose-file)
                compose_file="$2"
                shift 2
                ;;
            -e|--env-file)
                env_file="$2"
                shift 2
                ;;
            -s|--start)
                action="start"
                shift
                ;;
            -S|--stop)
                action="stop"
                shift
                ;;
            -r|--restart)
                action="restart"
                shift
                ;;
            -l|--logs)
                action="logs"
                shift
                ;;
            -m|--monitor)
                monitor=true
                shift
                ;;
            -c|--clean)
                action="clean"
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
    
    # 检查Docker环境
    check_docker
    
    # 创建必要目录
    create_directories
    
    # 检查环境变量文件
    check_env_file "$env_file"
    
    # 执行操作
    case $action in
        start)
            start_services "$compose_file" "$env_file" "$monitor"
            show_status "$compose_file" "$env_file"
            ;;
        stop)
            stop_services "$compose_file" "$env_file"
            ;;
        restart)
            restart_services "$compose_file" "$env_file"
            show_status "$compose_file" "$env_file"
            ;;
        logs)
            show_logs "$compose_file" "$env_file"
            ;;
        clean)
            clean_services "$compose_file" "$env_file"
            ;;
        "")
            echo -e "${YELLOW}请指定操作，使用 -h 查看帮助${NC}"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@" 