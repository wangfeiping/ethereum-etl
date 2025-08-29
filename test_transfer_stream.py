#!/usr/bin/env python3
"""
转账交易流式处理测试脚本
用于验证流式处理功能是否正常工作
"""

import os
import sys
import time
import logging
import tempfile
import subprocess
from pathlib import Path

# 添加项目路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def setup_logging():
    """设置日志"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger('TransferStreamTest')

def check_dependencies():
    """检查依赖"""
    logger = logging.getLogger('TransferStreamTest')
    
    try:
        import ethereumetl
        logger.info("✓ ethereumetl 模块可用")
    except ImportError as e:
        logger.error(f"✗ ethereumetl 模块不可用: {e}")
        return False
    
    try:
        import click
        logger.info("✓ click 模块可用")
    except ImportError as e:
        logger.error(f"✗ click 模块不可用: {e}")
        return False
    
    return True

def test_streamer_import():
    """测试流式处理器导入"""
    logger = logging.getLogger('TransferStreamTest')
    
    try:
        from ethereumetl.cli.stream_transfer_transactions import TransferTransactionStreamer
        logger.info("✓ TransferTransactionStreamer 类导入成功")
        return True
    except ImportError as e:
        logger.error(f"✗ TransferTransactionStreamer 类导入失败: {e}")
        return False

def test_basic_functionality():
    """测试基本功能"""
    logger = logging.getLogger('TransferStreamTest')
    
    # 创建临时目录
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        
        # 测试参数
        test_params = {
            'provider_uri': 'https://mainnet.infura.io',
            'transfer_transactions_output': str(temp_path / 'test_transfers.csv'),
            'last_synced_block_file': str(temp_path / 'test_last_block.txt'),
            'lag': 0,
            'start_block': None,
            'period_seconds': 1,
            'batch_size': 10,
            'max_workers': 2,
            'export_blocks': False,
            'export_transactions': True,
            'pid_file': None
        }
        
        try:
            from ethereumetl.cli.stream_transfer_transactions import TransferTransactionStreamer
            
            # 创建流式处理器实例
            streamer = TransferTransactionStreamer(**test_params)
            logger.info("✓ TransferTransactionStreamer 实例创建成功")
            
            # 测试获取当前区块号
            try:
                current_block = streamer._get_current_block_number()
                logger.info(f"✓ 获取当前区块号成功: {current_block}")
            except Exception as e:
                logger.warning(f"⚠ 获取当前区块号失败: {e}")
            
            return True
            
        except Exception as e:
            logger.error(f"✗ 基本功能测试失败: {e}")
            return False

def test_script_execution():
    """测试脚本执行"""
    logger = logging.getLogger('TransferStreamTest')
    
    script_path = Path(__file__).parent / 'ethereumetl' / 'cli' / 'stream_transfer_transactions.py'
    
    if not script_path.exists():
        logger.error(f"✗ 脚本文件不存在: {script_path}")
        return False
    
    try:
        # 测试脚本是否可以正常导入
        result = subprocess.run([
            sys.executable, '-c', 
            f'import sys; sys.path.insert(0, "{Path(__file__).parent}"); import ethereumetl.cli.stream_transfer_transactions'
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            logger.info("✓ 脚本导入测试成功")
        else:
            logger.error(f"✗ 脚本导入测试失败: {result.stderr}")
            return False
        
        return True
        
    except subprocess.TimeoutExpired:
        logger.error("✗ 脚本导入测试超时")
        return False
    except Exception as e:
        logger.error(f"✗ 脚本执行测试失败: {e}")
        return False

def test_shell_scripts():
    """测试Shell脚本"""
    logger = logging.getLogger('TransferStreamTest')
    
    scripts = [
        'start_transfer_stream.sh',
        'stop_transfer_stream.sh', 
        'status_transfer_stream.sh'
    ]
    
    for script in scripts:
        script_path = Path(__file__).parent / script
        
        if not script_path.exists():
            logger.error(f"✗ Shell脚本不存在: {script_path}")
            return False
        
        if not os.access(script_path, os.X_OK):
            logger.error(f"✗ Shell脚本无执行权限: {script_path}")
            return False
        
        logger.info(f"✓ Shell脚本检查通过: {script}")
    
    return True

def run_integration_test():
    """运行集成测试"""
    logger = logging.getLogger('TransferStreamTest')
    
    logger.info("开始集成测试...")
    
    # 创建临时目录
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        
        # 测试配置
        test_config = {
            'output_file': str(temp_path / 'test_transfers.csv'),
            'log_file': str(temp_path / 'test_stream.log'),
            'pid_file': str(temp_path / 'test_stream.pid'),
            'start_block': '18000000',  # 使用一个较早的区块
            'period_seconds': '1',
            'batch_size': '5',
            'max_workers': '1'
        }
        
        try:
            # 启动流式处理（短时间运行）
            start_cmd = [
                './start_transfer_stream.sh',
                '-s', test_config['start_block'],
                '-o', test_config['output_file'],
                '--log-file', test_config['log_file'],
                '--pid-file', test_config['pid_file'],
                '-t', test_config['period_seconds'],
                '-b', test_config['batch_size'],
                '-w', test_config['max_workers']
            ]
            
            logger.info(f"启动命令: {' '.join(start_cmd)}")
            
            # 启动进程
            process = subprocess.Popen(
                start_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=Path(__file__).parent
            )
            
            # 等待一段时间让进程运行
            time.sleep(10)
            
            # 检查进程是否还在运行
            if process.poll() is None:
                logger.info("✓ 流式处理进程正在运行")
                
                # 检查输出文件
                if Path(test_config['output_file']).exists():
                    logger.info("✓ 输出文件已创建")
                else:
                    logger.warning("⚠ 输出文件未创建")
                
                # 检查日志文件
                if Path(test_config['log_file']).exists():
                    logger.info("✓ 日志文件已创建")
                    # 显示日志内容
                    with open(test_config['log_file'], 'r') as f:
                        log_content = f.read()
                        logger.info(f"日志内容:\n{log_content}")
                else:
                    logger.warning("⚠ 日志文件未创建")
                
                # 停止进程
                process.terminate()
                process.wait(timeout=10)
                logger.info("✓ 流式处理进程已停止")
                
            else:
                stdout, stderr = process.communicate()
                logger.error(f"✗ 流式处理进程异常退出")
                logger.error(f"stdout: {stdout.decode()}")
                logger.error(f"stderr: {stderr.decode()}")
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"✗ 集成测试失败: {e}")
            return False

def main():
    """主函数"""
    logger = setup_logging()
    
    logger.info("=" * 50)
    logger.info("转账交易流式处理功能测试")
    logger.info("=" * 50)
    
    tests = [
        ("依赖检查", check_dependencies),
        ("流式处理器导入", test_streamer_import),
        ("基本功能", test_basic_functionality),
        ("脚本执行", test_script_execution),
        ("Shell脚本", test_shell_scripts),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        logger.info(f"\n--- {test_name} ---")
        try:
            if test_func():
                logger.info(f"✓ {test_name} 通过")
                passed += 1
            else:
                logger.error(f"✗ {test_name} 失败")
        except Exception as e:
            logger.error(f"✗ {test_name} 异常: {e}")
    
    logger.info(f"\n--- 测试结果 ---")
    logger.info(f"通过: {passed}/{total}")
    
    if passed == total:
        logger.info("✓ 所有测试通过！")
        
        # 询问是否运行集成测试
        try:
            response = input("\n是否运行集成测试？(y/N): ").strip().lower()
            if response in ['y', 'yes']:
                logger.info("\n--- 集成测试 ---")
                if run_integration_test():
                    logger.info("✓ 集成测试通过！")
                else:
                    logger.error("✗ 集成测试失败")
        except KeyboardInterrupt:
            logger.info("\n用户取消集成测试")
    else:
        logger.error("✗ 部分测试失败，请检查错误信息")
        return 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main()) 