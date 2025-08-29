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

import click
import logging
import os
import time
import json
from datetime import datetime

from ethereumetl.jobs.export_transfer_transactions_job import ExportTransferTransactionsJob
from ethereumetl.providers.auto import get_provider_from_uri
from ethereumetl.thread_local_proxy import ThreadLocalProxy
from ethereumetl.web3_utils import build_web3
from blockchainetl.logging_utils import logging_basic_config
from blockchainetl.file_utils import smart_open


class TransferTransactionStreamer:
    """
    转账交易流式处理器：持续监控新区块并导出转账交易
    """
    
    def __init__(
            self,
            provider_uri,
            transfer_transactions_output,
            last_synced_block_file='last_synced_transfer_block.txt',
            lag=0,
            start_block=None,
            period_seconds=10,
            batch_size=100,
            max_workers=5,
            export_blocks=False,
            export_transactions=True,
            pid_file=None):
        
        self.provider_uri = provider_uri
        self.transfer_transactions_output = transfer_transactions_output
        self.last_synced_block_file = last_synced_block_file
        self.lag = lag
        self.start_block = start_block
        self.period_seconds = period_seconds
        self.batch_size = batch_size
        self.max_workers = max_workers
        self.export_blocks = export_blocks
        self.export_transactions = export_transactions
        self.pid_file = pid_file
        
        # 初始化Web3提供者
        self.batch_web3_provider = ThreadLocalProxy(lambda: get_provider_from_uri(provider_uri, batch=True))
        
        # 初始化日志
        self.logger = logging.getLogger('TransferTransactionStreamer')
        
        # 初始化同步状态
        if self.start_block is not None or not os.path.isfile(self.last_synced_block_file):
            self._init_last_synced_block_file((self.start_block or 0) - 1)
        
        self.last_synced_block = self._read_last_synced_block()
        
    def _init_last_synced_block_file(self, start_block):
        """初始化最后同步区块文件"""
        if os.path.isfile(self.last_synced_block_file):
            raise ValueError(
                f'{self.last_synced_block_file} 不应该存在如果指定了 --start-block 选项。'
                f'请删除 {self.last_synced_block_file} 文件或移除 --start-block 选项。'
            )
        self._write_last_synced_block(start_block)
        
    def _read_last_synced_block(self):
        """读取最后同步的区块号"""
        with smart_open(self.last_synced_block_file, 'r') as f:
            return int(f.read().strip())
            
    def _write_last_synced_block(self, block_number):
        """写入最后同步的区块号"""
        with smart_open(self.last_synced_block_file, 'w') as f:
            f.write(str(block_number) + '\n')
            
    def _get_current_block_number(self):
        """获取当前网络最新区块号"""
        w3 = build_web3(self.batch_web3_provider)
        return int(w3.eth.get_block("latest").number)
        
    def _export_transfer_transactions(self, start_block, end_block):
        """导出指定区块范围内的转账交易"""
        self.logger.info(f"导出区块 {start_block} 到 {end_block} 的转账交易")
        
        job = ExportTransferTransactionsJob(
            start_block=start_block,
            end_block=end_block,
            batch_size=self.batch_size,
            batch_web3_provider=self.batch_web3_provider,
            max_workers=self.max_workers,
            transfer_transactions_output=self.transfer_transactions_output,
            export_blocks=self.export_blocks,
            export_transactions=self.export_transactions
        )
        
        job.run()
        
    def _sync_cycle(self):
        """执行一次同步周期"""
        current_block = self._get_current_block_number()
        
        # 计算目标区块（考虑延迟）
        target_block = current_block - self.lag
        
        # 确保不超过批量大小
        target_block = min(target_block, self.last_synced_block + self.batch_size)
        
        blocks_to_sync = max(target_block - self.last_synced_block, 0)
        
        self.logger.info(f'当前区块: {current_block}, 目标区块: {target_block}, '
                        f'最后同步区块: {self.last_synced_block}, 待同步区块数: {blocks_to_sync}')
        
        if blocks_to_sync > 0:
            try:
                self._export_transfer_transactions(self.last_synced_block + 1, target_block)
                self.logger.info(f'写入最后同步区块: {target_block}')
                self._write_last_synced_block(target_block)
                self.last_synced_block = target_block
                return blocks_to_sync
            except Exception as e:
                self.logger.error(f'导出转账交易时发生错误: {e}')
                raise e
                
        return 0
        
    def stream(self):
        """开始流式处理"""
        try:
            if self.pid_file is not None:
                self.logger.info(f'创建PID文件: {self.pid_file}')
                with open(self.pid_file, 'w') as f:
                    f.write(str(os.getpid()))
                    
            self.logger.info(f'开始转账交易流式处理，从区块 {self.last_synced_block + 1} 开始')
            
            while True:
                synced_blocks = 0
                
                try:
                    synced_blocks = self._sync_cycle()
                except Exception as e:
                    self.logger.exception('同步区块数据时发生异常')
                    # 可以选择是否重试
                    raise e
                    
                if synced_blocks <= 0:
                    self.logger.info(f'没有需要同步的区块，休眠 {self.period_seconds} 秒...')
                    time.sleep(self.period_seconds)
                    
        finally:
            if self.pid_file is not None:
                self.logger.info(f'删除PID文件: {self.pid_file}')
                try:
                    os.remove(self.pid_file)
                except OSError:
                    pass


@click.command(context_settings=dict(help_option_names=['-h', '--help']))
@click.option('-l', '--last-synced-block-file', default='last_synced_transfer_block.txt', 
              show_default=True, type=str, help='记录最后同步区块的文件')
@click.option('--lag', default=0, show_default=True, type=int, 
              help='滞后于网络的区块数量')
@click.option('-p', '--provider-uri', default='https://mainnet.infura.io', 
              show_default=True, type=str,
              help='Web3提供者的URI，例如: https://mainnet.infura.io')
@click.option('-o', '--transfer-transactions-output', default='transfer_transactions_stream.csv', 
              show_default=True, type=str,
              help='转账交易输出文件')
@click.option('-s', '--start-block', default=None, show_default=True, type=int, 
              help='开始区块号')
@click.option('--period-seconds', default=10, show_default=True, type=int, 
              help='同步间隔秒数')
@click.option('-b', '--batch-size', default=100, show_default=True, type=int, 
              help='单次请求的区块数量')
@click.option('-w', '--max-workers', default=5, show_default=True, type=int, 
              help='最大工作线程数')
@click.option('--export-blocks/--no-export-blocks', default=False, show_default=True,
              help='是否导出区块数据')
@click.option('--export-transactions/--no-export-transactions', default=True, show_default=True,
              help='是否导出交易数据')
@click.option('--log-file', default=None, show_default=True, type=str, 
              help='日志文件')
@click.option('--pid-file', default=None, show_default=True, type=str, 
              help='PID文件')
def stream_transfer_transactions(
        last_synced_block_file, lag, provider_uri, transfer_transactions_output,
        start_block, period_seconds, batch_size, max_workers,
        export_blocks, export_transactions, log_file, pid_file):
    """持续流式导出转账交易（value > 0的交易）"""
    
    # 配置日志
    if log_file:
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
    else:
        logging_basic_config()
    
    if not export_blocks and not export_transactions:
        raise ValueError('export_blocks 和 export_transactions 至少有一个必须为 True')
    
    if transfer_transactions_output is None or transfer_transactions_output == '':
        transfer_transactions_output = None
    
    # 创建流式处理器
    streamer = TransferTransactionStreamer(
        provider_uri=provider_uri,
        transfer_transactions_output=transfer_transactions_output,
        last_synced_block_file=last_synced_block_file,
        lag=lag,
        start_block=start_block,
        period_seconds=period_seconds,
        batch_size=batch_size,
        max_workers=max_workers,
        export_blocks=export_blocks,
        export_transactions=export_transactions,
        pid_file=pid_file
    )
    
    # 开始流式处理
    streamer.stream()


if __name__ == '__main__':
    stream_transfer_transactions() 