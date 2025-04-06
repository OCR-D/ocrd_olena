import click

from ocrd.decorators import ocrd_cli_options, ocrd_cli_wrap_processor
from .processor import ScriboProcessor

@click.command()
@ocrd_cli_options
def ocrd_olena_binarize(*args, **kwargs):
    return ocrd_cli_wrap_processor(ScriboProcessor, *args, **kwargs)
