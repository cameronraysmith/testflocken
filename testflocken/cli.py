import rich_click as click


from .app import testflocken

__all__: list[str] = []


@click.command("testflocken", context_settings={"help_option_names": ("--help", "-h")})
@click.version_option(None, "--version", "-v")
@click.argument("x", type=int, required=True)
@click.argument("y", type=int, required=True)
def testflocken_cli(x: int, y: int):
    """
    testflocken addition

    Arguments:
    x: number 1
    y: number 2
    """

    click.echo(f"The sum is: {testflocken(x,y)}")


if __name__ == "__main__":
    testflocken_cli()
