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
import sys

from ethereumetl.jobs.export_transfer_transactions_job import ExportTransferTransactionsJob
from ethereumetl.providers.auto import get_provider_from_uri
from ethereumetl.thread_local_proxy import ThreadLocalProxy
from blockchainetl.logging_utils import logging_basic_config


@click.command(context_settings=dict(help_option_names=['-h', '--help']))
@click.option('-s', '--start-block', default=0, show_default=True, type=int, help='Start block')
@click.option('-e', '--end-block', required=True, type=int, help='End block')
@click.option('-b', '--batch-size', default=100, show_default=True, type=int, help='The number of blocks to export at a time.')
@click.option('-w', '--max-workers', default=5, show_default=True, type=int, help='The maximum number of workers.')
@click.option('-p', '--provider-uri', default='https://mainnet.infura.io', show_default=True, type=str,
              help='The URI of the web3 provider e.g. '
                   'file://$HOME/Library/Ethereum/geth.ipc or https://mainnet.infura.io')
@click.option('-o', '--transfer-transactions-output', default='transfer_transactions.csv', show_default=True, type=str,
              help='The output file for transfer transactions. If not provided transfer transactions will not be exported.')
@click.option('--request-per-second', default=5, show_default=True, type=float,
              help='Maximum requests per second for RPC calls. If not specified, no rate limiting will be applied.')
@click.option('--export-blocks/--no-export-blocks', default=False, show_default=True,
              help='Whether to export blocks.')
@click.option('--export-transactions/--no-export-transactions', default=True, show_default=True,
              help='Whether to export transactions.')
def export_transfer_transactions(start_block, end_block, batch_size, max_workers, provider_uri,
                                transfer_transactions_output, request_per_second, export_blocks, export_transactions):
    """Exports transfer transactions (transactions with value > 0)."""
    logging_basic_config()

    if not export_blocks and not export_transactions:
        raise ValueError('At least one of export_blocks or export_transactions must be True')

    if transfer_transactions_output is None or transfer_transactions_output == '':
        transfer_transactions_output = None

    job = ExportTransferTransactionsJob(
        start_block=start_block,
        end_block=end_block,
        batch_size=batch_size,
        batch_web3_provider=ThreadLocalProxy(lambda: get_provider_from_uri(provider_uri, batch=True)),
        max_workers=max_workers,
        transfer_transactions_output=transfer_transactions_output,
        request_per_second=request_per_second,
        export_blocks=export_blocks,
        export_transactions=export_transactions
    )

    job.run() 