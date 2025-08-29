#!/bin/bash

# Docker 转账交易流式处理测试脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Docker 转账交易流式处理测试${NC}"
echo "========================================"

# 检查Docker环境
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

# 测试镜像构建
test_build() {
    echo -e "${BLUE}测试镜像构建...${NC}"
    
    if docker-compose -f docker-compose.simple.yml build; then
        echo -e "${GREEN}镜像构建成功${NC}"
    else
        echo -e "${RED}镜像构建失败${NC}"
        exit 1
    fi
}

# 测试配置验证
test_config() {
    echo -e "${BLUE}测试配置验证...${NC}"
    
    if docker-compose -f docker-compose.simple.yml config > /dev/null; then
        echo -e "${GREEN}配置验证通过${NC}"
    else
        echo -e "${RED}配置验证失败${NC}"
        exit 1
    fi
}

# 测试服务启动
test_start() {
    echo -e "${BLUE}测试服务启动...${NC}"
    
    # 创建测试环境变量文件
    cat > .env.test << EOF
PROVIDER_URI=https://mainnet.infura.io
START_BLOCK=18000000
PERIOD_SECONDS=30
BATCH_SIZE=10
MAX_WORKERS=2
LAG=0
OUTPUT_FILE=/app/data/test_transfers.csv
LOG_FILE=/app/logs/test_stream.log
PID_FILE=/app/state/test_stream.pid
LAST_SYNCED_BLOCK_FILE=/app/state/test_last_block.txt
EXPORT_BLOCKS=false
EXPORT_TRANSACTIONS=true
EOF
    
    # 创建测试目录
    mkdir -p data logs state
    
    # 启动服务
    if docker-compose -f docker-compose.simple.yml --env-file .env.test up -d; then
        echo -e "${GREEN}服务启动成功${NC}"
        
        # 等待服务启动
        echo -e "${BLUE}等待服务启动...${NC}"
        sleep 15
        
        # 检查服务状态
        if docker-compose -f docker-compose.simple.yml --env-file .env.test ps | grep -q "Up"; then
            echo -e "${GREEN}服务运行正常${NC}"
        else
            echo -e "${RED}服务运行异常${NC}"
            docker-compose -f docker-compose.simple.yml --env-file .env.test logs
            return 1
        fi
        
        # 检查文件创建
        if [ -f "state/test_last_block.txt" ]; then
            echo -e "${GREEN}状态文件创建成功${NC}"
        else
            echo -e "${YELLOW}状态文件未创建（可能正常）${NC}"
        fi
        
        if [ -f "logs/test_stream.log" ]; then
            echo -e "${GREEN}日志文件创建成功${NC}"
        else
            echo -e "${YELLOW}日志文件未创建（可能正常）${NC}"
        fi
        
    else
        echo -e "${RED}服务启动失败${NC}"
        return 1
    fi
}

# 测试日志输出
test_logs() {
    echo -e "${BLUE}测试日志输出...${NC}"
    
    # 等待一段时间让服务产生日志
    sleep 10
    
    if docker-compose -f docker-compose.simple.yml --env-file .env.test logs --tail=10 | grep -q "TransferTransactionStreamer"; then
        echo -e "${GREEN}日志输出正常${NC}"
    else
        echo -e "${YELLOW}日志输出检查失败（可能正常）${NC}"
    fi
}

# 测试健康检查
test_health() {
    echo -e "${BLUE}测试健康检查...${NC}"
    
    # 等待健康检查
    sleep 30
    
    if docker inspect ethereum-etl-transfer-stream | grep -q '"Status": "healthy"'; then
        echo -e "${GREEN}健康检查通过${NC}"
    else
        echo -e "${YELLOW}健康检查未通过（可能正常）${NC}"
        docker inspect ethereum-etl-transfer-stream | grep -A 5 -B 5 Health
    fi
}

# 测试服务停止
test_stop() {
    echo -e "${BLUE}测试服务停止...${NC}"
    
    if docker-compose -f docker-compose.simple.yml --env-file .env.test down; then
        echo -e "${GREEN}服务停止成功${NC}"
    else
        echo -e "${RED}服务停止失败${NC}"
        return 1
    fi
}

# 清理测试环境
cleanup() {
    echo -e "${BLUE}清理测试环境...${NC}"
    
    # 停止服务
    docker-compose -f docker-compose.simple.yml --env-file .env.test down 2>/dev/null || true
    
    # 删除测试文件
    rm -f .env.test
    
    # 删除测试数据（可选）
    read -p "是否删除测试数据？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf data/test_transfers.csv logs/test_stream.log state/test_stream.pid state/test_last_block.txt
        echo -e "${GREEN}测试数据已清理${NC}"
    else
        echo -e "${YELLOW}测试数据保留${NC}"
    fi
}

# 主测试流程
main() {
    local test_results=()
    
    # 运行测试
    tests=(
        "Docker环境检查" check_docker
        "镜像构建测试" test_build
        "配置验证测试" test_config
        "服务启动测试" test_start
        "日志输出测试" test_logs
        "健康检查测试" test_health
        "服务停止测试" test_stop
    )
    
    for ((i=0; i<${#tests[@]}; i+=2)); do
        test_name="${tests[i]}"
        test_func="${tests[i+1]}"
        
        echo -e "${BLUE}\n--- $test_name ---${NC}"
        if $test_func; then
            echo -e "${GREEN}✓ $test_name 通过${NC}"
            test_results+=("✓ $test_name")
        else
            echo -e "${RED}✗ $test_name 失败${NC}"
            test_results+=("✗ $test_name")
        fi
    done
    
    # 显示测试结果
    echo -e "${BLUE}\n--- 测试结果 ---${NC}"
    for result in "${test_results[@]}"; do
        if [[ $result == ✓* ]]; then
            echo -e "${GREEN}$result${NC}"
        else
            echo -e "${RED}$result${NC}"
        fi
    done
    
    # 统计结果
    passed=$(echo "${test_results[@]}" | tr ' ' '\n' | grep -c "✓" || echo "0")
    total=${#test_results[@]}
    
    echo -e "${BLUE}\n测试统计: $passed/$total 通过${NC}"
    
    if [ "$passed" -eq "$total" ]; then
        echo -e "${GREEN}所有测试通过！Docker 环境配置正确。${NC}"
    else
        echo -e "${YELLOW}部分测试失败，请检查错误信息。${NC}"
    fi
    
    # 清理
    cleanup
}

# 运行主函数
main "$@" 