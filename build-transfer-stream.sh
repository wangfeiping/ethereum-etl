#!/bin/bash

# 转账交易流式处理 Docker 构建脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}构建转账交易流式处理 Docker 镜像${NC}"
echo "========================================"

# 检查必要文件
echo -e "${BLUE}检查必要文件...${NC}"
if [ ! -f "quick-start-docker.sh" ]; then
    echo -e "${RED}错误: 未找到 quick-start-docker.sh${NC}"
    exit 1
fi

if [ ! -f "ethereumetl/cli/stream_transfer_transactions.py" ]; then
    echo -e "${RED}错误: 未找到 stream_transfer_transactions.py${NC}"
    exit 1
fi

if [ ! -f "Dockerfile.transfer-stream" ]; then
    echo -e "${RED}错误: 未找到 Dockerfile.transfer-stream${NC}"
    exit 1
fi

# 设置镜像标签
IMAGE_NAME="ethereum-etl-transfer-stream"
TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

echo -e "${BLUE}构建 Docker 镜像: ${FULL_IMAGE_NAME}${NC}"

# 执行 Docker build 命令
docker build \
    -f Dockerfile.transfer-stream \
    -t ${FULL_IMAGE_NAME} \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") \
    .

# 检查构建结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker 镜像构建成功！${NC}"
    echo ""
    echo -e "${BLUE}镜像信息:${NC}"
    docker images ${FULL_IMAGE_NAME}
    echo ""
    echo -e "${BLUE}使用方法:${NC}"
    echo "  运行容器: docker run -it ${FULL_IMAGE_NAME}"
    echo "  查看帮助: docker run ${FULL_IMAGE_NAME} --help"
    echo "  挂载数据: docker run -v \$(pwd)/data:/app/data ${FULL_IMAGE_NAME}"
    echo ""
    echo -e "${BLUE}示例命令:${NC}"
    echo "  docker run -it ${FULL_IMAGE_NAME} \\"
    echo "    --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \\"
    echo "    --transfer-transactions-output /app/data/transfers.csv \\"
    echo "    --period-seconds 10 \\"
    echo "    --batch-size 100"
else
    echo -e "${RED}Docker 镜像构建失败！${NC}"
    exit 1
fi 