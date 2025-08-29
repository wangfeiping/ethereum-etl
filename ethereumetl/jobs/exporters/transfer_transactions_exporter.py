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
        
    def convert_item(self, item):
        # 只处理交易类型的项目
        if item.get('type') != 'transaction':
            return item
            
        # 检查是否为转账交易（有value字段且不为0）
        value = item.get('value', '0')
        if value and value != '0' and value != 0:
            # 这是一个转账交易
            block_number = item.get('block_number', 'unknown')
            transaction_hash = item.get('hash', 'unknown')
            
            # 输出日志
            self.logger.info(f"Transfer Transaction Found - Block: {block_number}, Hash: {transaction_hash}")
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
            # 检查是否为转账交易
            value = item.get('value', '0')
            if value and value != '0' and value != 0:
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