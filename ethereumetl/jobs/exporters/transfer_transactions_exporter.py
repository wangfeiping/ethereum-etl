# MIT License
#
# Copyright (c) 2018 Evgeny Medvedev, evge.medvedev@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import logging
from blockchainetl.jobs.exporters.composite_item_exporter import CompositeItemExporter
from blockchainetl.jobs.exporters.converters.composite_item_converter import CompositeItemConverter


class TransferTransactionConverter:
    """
    转换器：过滤出转账交易并添加日志输出
    """
    
    def __init__(self):
        self.logger = logging.getLogger('TransferTransactionConverter')
        self.transfer_count = 0
        
        # ERC20 transfer method signature: transfer(address,uint256)
        self.ERC20_TRANSFER_SIGNATURE = "a9059cbb"
        
    def _is_erc20_transfer(self, input_data):
        """检查是否为ERC20转账交易"""
        if not input_data or input_data == "0x":
            return False
        # 移除0x前缀并检查前4个字节是否为ERC20 transfer方法签名
        input_hex = input_data[2:] if input_data.startswith("0x") else input_data
        return input_hex.startswith(self.ERC20_TRANSFER_SIGNATURE)
        
    def _is_eth_transfer(self, input_data, value):
        """检查是否为ETH转账交易"""
        # ETH转账：input为空或0x，且value大于0
        return (not input_data or input_data == "0x") and value and value != '0' and value != 0
        
    def convert_item(self, item):
        # 只处理交易类型的项目
        if item.get('type') != 'transaction':
            return item
            
        # 检查是否为转账交易
        value = item.get('value', '0')
        input_data = item.get('input', '')
        
        # 判断是否为转账交易：
        # 1. ETH转账：value > 0 且 input为空或0x
        # 2. ERC20转账：input包含ERC20 transfer方法签名
        is_eth_transfer = self._is_eth_transfer(input_data, value)
        is_erc20_transfer = self._is_erc20_transfer(input_data)
        
        if is_eth_transfer or is_erc20_transfer:
            # 这是一个转账交易
            block_number = item.get('block_number', 'unknown')
            transaction_hash = item.get('hash', 'unknown')
            from_address = item.get('from_address', 'unknown')
            to_address = item.get('to_address', 'unknown')
            
            # 判断转账类型
            if is_erc20_transfer:
                # ERC20转账
                contract_address = to_address  # ERC20转账的目标地址就是合约地址
                self.logger.warning(f"ERC20 Transfer - Block: {block_number}, Hash: {transaction_hash}, "
                               f"From: {from_address}, To: {to_address}, Contract: {contract_address}")
            elif is_eth_transfer:
                # ETH转账
                self.logger.warning(f"ETH Transfer - Block: {block_number}, Hash: {transaction_hash}, "
                               f"From: {from_address}, To: {to_address}, Type: ETH")
            else:
                # 其他类型的转账（可能是合约调用等）
                self.logger.warning(f"Other Transfer - Block: {block_number}, Hash: {transaction_hash}, "
                               f"From: {from_address}, To: {to_address}")
            
            self.transfer_count += 1
            
            # 每1000个转账交易输出一次统计
            if self.transfer_count % 1000 == 0:
                self.logger.info(f"Total transfer transactions processed: {self.transfer_count}")
        
        return item


class TransferTransactionsItemExporter:
    """
    转账交易导出器：导出所有转账交易并通过日志输出区块高度和交易哈希
    """
    
    def __init__(self, transfer_transactions_output=None, converters=()):
        self.transfer_transactions_output = transfer_transactions_output
        self.converters = list(converters)
        
        # 添加转账交易转换器
        self.transfer_converter = TransferTransactionConverter()
        self.converters.append(self.transfer_converter)
        
        # 定义转账交易要导出的字段
        self.TRANSFER_TRANSACTION_FIELDS_TO_EXPORT = [
            'hash',
            'nonce',
            'block_hash',
            'block_number',
            'transaction_index',
            'from_address',
            'to_address',
            'value',
            'gas',
            'gas_price',
            'input',
            'block_timestamp',
            'max_fee_per_gas',
            'max_priority_fee_per_gas',
            'transaction_type',
            'max_fee_per_blob_gas',
            'blob_versioned_hashes'
        ]
        
        # 创建复合导出器
        self.composite_exporter = CompositeItemExporter(
            filename_mapping={
                'transfer_transaction': transfer_transactions_output
            },
            field_mapping={
                'transfer_transaction': self.TRANSFER_TRANSACTION_FIELDS_TO_EXPORT
            },
            converters=self.converters
        )
        
        self.logger = logging.getLogger('TransferTransactionsItemExporter')
        
    def open(self):
        self.logger.info("Opening TransferTransactionsItemExporter")
        self.composite_exporter.open()
        
    def export_items(self, items):
        for item in items:
            self.export_item(item)
            
    def export_item(self, item):
        # 只处理交易类型的项目
        if item.get('type') == 'transaction':
            # 首先通过TransferTransactionConverter处理，这会输出日志
            converted_item = self.transfer_converter.convert_item(item)
            
            # 检查是否为转账交易
            value = item.get('value', '0')
            input_data = item.get('input', '')
            
            # 判断是否为转账交易：
            # 1. ETH转账：value > 0 且 input为空或0x
            # 2. ERC20转账：input包含ERC20 transfer方法签名
            is_eth_transfer = self.transfer_converter._is_eth_transfer(input_data, value)
            is_erc20_transfer = self.transfer_converter._is_erc20_transfer(input_data)
            
            if is_eth_transfer or is_erc20_transfer:
                # 转换为转账交易类型并导出
                transfer_item = item.copy()
                transfer_item['type'] = 'transfer_transaction'
                self.composite_exporter.export_item(transfer_item)
        
        # 不导出原始项目，只导出转账交易
        
    def close(self):
        self.logger.info(f"Closing TransferTransactionsItemExporter. Total transfer transactions: {self.transfer_converter.transfer_count}")
        self.composite_exporter.close()


def transfer_transactions_item_exporter(transfer_transactions_output=None, converters=()):
    """
    创建转账交易导出器的工厂函数
    
    Args:
        transfer_transactions_output: 转账交易输出文件路径
        converters: 额外的转换器列表
    
    Returns:
        TransferTransactionsItemExporter实例
    """
    return TransferTransactionsItemExporter(
        transfer_transactions_output=transfer_transactions_output,
        converters=converters
    ) 