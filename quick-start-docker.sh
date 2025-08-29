#!/bin/bash

# 快速启动 Docker 转账交易流式处理

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}快速启动 Docker 转账交易流式处理${NC}"
echo "========================================"

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未找到 Docker${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: 未找到 Docker Compose${NC}"
    exit 1
fi

# 创建目录
echo -e "${BLUE}创建必要的目录...${NC}"
mkdir -p data logs state

# 检查环境变量文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}创建环境变量文件...${NC}"
    cp env.example .env
    echo -e "${YELLOW}请编辑 .env 文件，设置您的 Infura 项目ID${NC}"
    echo -e "${YELLOW}特别是 PROVIDER_URI 参数${NC}"
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# 构建和启动
echo -e "${BLUE}构建 Docker 镜像...${NC}"
docker-compose -f docker-compose.simple.yml build

echo -e "${BLUE}启动转账交易流式处理服务...${NC}"
docker-compose -f docker-compose.simple.yml up -d

# 等待服务启动
echo -e "${BLUE}等待服务启动...${NC}"
sleep 10

# 检查状态
echo -e "${BLUE}检查服务状态...${NC}"
docker-compose -f docker-compose.simple.yml ps

echo -e "${GREEN}服务启动完成！${NC}"
echo ""
echo -e "${BLUE}有用的命令:${NC}"
echo "  查看日志: docker-compose -f docker-compose.simple.yml logs -f"
echo "  停止服务: docker-compose -f docker-compose.simple.yml down"
echo "  重启服务: docker-compose -f docker-compose.simple.yml restart"
echo ""
echo -e "${BLUE}数据文件位置:${NC}"
echo "  转账数据: ./data/transfer_transactions.csv"
echo "  日志文件: ./logs/transfer_stream.log"
echo "  同步状态: ./state/last_synced_transfer_block.txt" 