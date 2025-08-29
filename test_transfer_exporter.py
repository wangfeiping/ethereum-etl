#!/usr/bin/env python3
"""
测试转账交易导出器
"""

import logging
import tempfile
import os
from ethereumetl.jobs.exporters.transfer_transactions_exporter import TransferTransactionsItemExporter

# 设置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

def create_test_transaction(block_number, tx_hash, value, from_addr, to_addr):
    """创建测试交易数据"""
    return {
        'type': 'transaction',
        'hash': tx_hash,
        'nonce': 0,
        'block_hash': f'0x{block_number:064x}',
        'block_number': block_number,
        'transaction_index': 0,
        'from_address': from_addr,
        'to_address': to_addr,
        'value': value,
        'gas': 21000,
        'gas_price': '20000000000',
        'input': '0x',
        'block_timestamp': 1600000000 + block_number,
        'max_fee_per_gas': None,
        'max_priority_fee_per_gas': None,
        'transaction_type': 0,
        'max_fee_per_blob_gas': None,
        'blob_versioned_hashes': None
    }

def test_transfer_exporter():
    """测试转账交易导出器"""
    print("开始测试转账交易导出器...")
    
    # 创建临时文件
    with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False) as temp_file:
        temp_filename = temp_file.name
    
    try:
        # 创建导出器
        exporter = TransferTransactionsItemExporter(transfer_transactions_output=temp_filename)
        exporter.open()
        
        # 创建测试数据
        test_items = [
            # 转账交易（value > 0）
            create_test_transaction(
                block_number=1000,
                tx_hash='0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
                value='1000000000000000000',  # 1 ETH
                from_addr='0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6',
                to_addr='0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b7'
            ),
            # 另一个转账交易
            create_test_transaction(
                block_number=1001,
                tx_hash='0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
                value='500000000000000000',  # 0.5 ETH
                from_addr='0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b8',
                to_addr='0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b9'
            ),
            # 非转账交易（value = 0）
            create_test_transaction(
                block_number=1002,
                tx_hash='0x0000000000000000000000000000000000000000000000000000000000000000',
                value='0',  # 0 ETH
                from_addr='0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8ba',
                to_addr='0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8bb'
            ),
            # 合约调用交易（value = 0，但有input数据）
            create_test_transaction(
                block_number=1003,
                tx_hash='0x1111111111111111111111111111111111111111111111111111111111111111',
                value='0',  # 0 ETH
                from_addr='0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8bc',
                to_addr='0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8bd'
            )
        ]
        
        # 导出数据
        print("导出测试数据...")
        exporter.export_items(test_items)
        
        # 关闭导出器
        exporter.close()
        
        # 检查输出文件
        if os.path.exists(temp_filename):
            print(f"输出文件已创建: {temp_filename}")
            
            # 读取文件内容
            with open(temp_filename, 'r') as f:
                content = f.read()
                print("文件内容:")
                print(content)
                
            # 检查是否只包含转账交易
            lines = content.strip().split('\n')
            if len(lines) > 1:  # 有标题行和数据行
                data_lines = lines[1:]  # 跳过标题行
                print(f"找到 {len(data_lines)} 个转账交易记录")
                
                # 验证每个记录都是转账交易
                for i, line in enumerate(data_lines):
                    if line.strip():
                        fields = line.split(',')
                        if len(fields) >= 8:  # 确保有足够的字段
                            value = fields[7]  # value字段
                            if value and value != '0' and value != '"0"':
                                print(f"记录 {i+1}: 确认是转账交易，value = {value}")
                            else:
                                print(f"记录 {i+1}: 非转账交易，value = {value}")
        else:
            print("错误：输出文件未创建")
            
    except Exception as e:
        print(f"测试过程中出现错误: {e}")
        import traceback
        traceback.print_exc()
        
    finally:
        # 清理临时文件
        if os.path.exists(temp_filename):
            os.unlink(temp_filename)
            print("临时文件已清理")

if __name__ == "__main__":
    test_transfer_exporter() 