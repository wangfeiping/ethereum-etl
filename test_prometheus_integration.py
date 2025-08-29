#!/usr/bin/env python3
"""
Prometheus 集成测试脚本
"""

import time
import requests
import subprocess
import signal
import sys
import os

def test_prometheus_metrics():
    """测试 Prometheus 指标"""
    print("🔍 测试 Prometheus 指标...")
    
    try:
        # 等待指标服务器启动
        time.sleep(3)
        
        # 获取指标
        response = requests.get('http://localhost:8000/metrics', timeout=10)
        
        if response.status_code == 200:
            metrics = response.text
            print("✅ Prometheus 指标服务器响应正常")
            
            # 检查关键指标
            expected_metrics = [
                'ethereum_etl_synced_height',
                'ethereum_etl_blocks_processed_total',
                'ethereum_etl_transactions_processed_total',
                'ethereum_etl_transfer_transactions_total',
                'ethereum_etl_processing_duration_seconds',
                'ethereum_etl_errors_total',
                'ethereum_etl_app_info'
            ]
            
            found_metrics = []
            for metric in expected_metrics:
                if metric in metrics:
                    found_metrics.append(metric)
                    print(f"  ✅ 找到指标: {metric}")
                else:
                    print(f"  ❌ 缺少指标: {metric}")
            
            print(f"\n📊 指标统计: {len(found_metrics)}/{len(expected_metrics)} 个指标可用")
            
            # 显示 synced_height 指标
            if 'ethereum_etl_synced_height' in metrics:
                print("\n📈 synced_height 指标示例:")
                for line in metrics.split('\n'):
                    if 'ethereum_etl_synced_height' in line and not line.startswith('#'):
                        print(f"  {line}")
            
            return len(found_metrics) == len(expected_metrics)
        else:
            print(f"❌ Prometheus 服务器响应异常: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ 无法连接到 Prometheus 服务器: {e}")
        return False
    except Exception as e:
        print(f"❌ 测试过程中发生错误: {e}")
        return False

def start_streamer():
    """启动流式处理器"""
    print("🚀 启动转账交易流式处理器...")
    
    # 使用测试网络和较短的同步间隔
    cmd = [
        'python', 'ethereumetl/cli/stream_transfer_transactions.py',
        '--provider-uri', 'https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',  # 使用 Goerli 测试网
        '--transfer-transactions-output', '/tmp/test_transfers.csv',
        '--period-seconds', '5',
        '--batch-size', '10',
        '--max-workers', '2',
        '--prometheus-port', '8000',
        '--start-block', '1000000'  # 从较早的区块开始
    ]
    
    try:
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"✅ 流式处理器已启动 (PID: {process.pid})")
        return process
    except Exception as e:
        print(f"❌ 启动流式处理器失败: {e}")
        return None

def stop_streamer(process):
    """停止流式处理器"""
    if process:
        print(f"🛑 停止流式处理器 (PID: {process.pid})...")
        try:
            process.terminate()
            process.wait(timeout=10)
            print("✅ 流式处理器已停止")
        except subprocess.TimeoutExpired:
            print("⚠️  强制终止流式处理器...")
            process.kill()
            process.wait()
        except Exception as e:
            print(f"❌ 停止流式处理器时发生错误: {e}")

def main():
    """主函数"""
    print("🧪 Prometheus 集成测试")
    print("=" * 50)
    
    # 检查依赖
    try:
        import prometheus_client
        print("✅ prometheus_client 已安装")
    except ImportError:
        print("❌ prometheus_client 未安装")
        print("请运行: pip install prometheus_client")
        return False
    
    # 启动流式处理器
    process = start_streamer()
    if not process:
        return False
    
    try:
        # 等待一段时间让处理器运行
        print("⏳ 等待流式处理器运行...")
        time.sleep(10)
        
        # 测试 Prometheus 指标
        success = test_prometheus_metrics()
        
        if success:
            print("\n🎉 Prometheus 集成测试成功！")
            print("\n📋 可用的指标:")
            print("  - ethereum_etl_synced_height: 已完成解析的区块高度")
            print("  - ethereum_etl_blocks_processed_total: 已处理的区块总数")
            print("  - ethereum_etl_transactions_processed_total: 已处理的交易总数")
            print("  - ethereum_etl_transfer_transactions_total: 已处理的转账交易总数")
            print("  - ethereum_etl_processing_duration_seconds: 处理时间")
            print("  - ethereum_etl_errors_total: 错误总数")
            print("  - ethereum_etl_app_info: 应用信息")
            
            print("\n🌐 访问指标:")
            print("  http://localhost:8000/metrics")
            
        else:
            print("\n❌ Prometheus 集成测试失败")
            
        return success
        
    finally:
        # 停止流式处理器
        stop_streamer(process)
        
        # 清理临时文件
        try:
            if os.path.exists('/tmp/test_transfers.csv'):
                os.remove('/tmp/test_transfers.csv')
        except:
            pass

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1) 