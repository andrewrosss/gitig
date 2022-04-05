from __future__ import annotations

import argparse
import sys
from pydoc import pager
from typing import NoReturn
from typing import Sequence
from urllib.parse import urljoin
from urllib.request import Request
from urllib.request import urlopen


__version__ = "1.0.0"


class Defaults:
    completion_shells = ("bash", "fish")
    api_url = "https://www.toptal.com/developers/gitignore/api"


def cli() -> NoReturn:
    raise SystemExit(main())


def main() -> int:
    parser = create_parser()
    args = parser.parse_args()

    if hasattr(args, "handler"):
        return args.handler(args)

    parser.print_help()
    return 1


def create_parser(
    parser: argparse.ArgumentParser | None = None,
) -> argparse.ArgumentParser:
    parser = parser or argparse.ArgumentParser()
    parser.add_argument("-v", "--version", action="version", version=__version__)
    parser.add_argument(
        "template",
        nargs="*",
        help="Template(s) to include in the generated .gitignore file. If no "
        "templates are specified, display a list of all available templates.",
    )
    parser.add_argument(
        "--completion",
        default=None,
        choices=Defaults.completion_shells,
        help="Generate a completion file for the selected shell.",
    )
    parser.add_argument(
        "--no-pager",
        default=False,
        action="store_true",
        help="Write template list to stdout. By default, this program attempts "
        "to paginate the list of available templates for easier reading.",
    )

    parser.set_defaults(handler=handler)

    return parser


def handler(args: argparse.Namespace) -> int:
    shell: str | None = args.completion
    templates: list[str] = args.template
    no_pager: bool = args.no_pager

    if shell:
        try:
            completion_fn = globals()[f"{shell}_completion"]
            print(completion_fn(), file=sys.stdout)
        except KeyError:
            print(_unknown_completion_shell_msg(shell))
            return 1
    elif len(templates) == 0:
        text = "\n".join(list_templates())
        if no_pager:
            print(text, file=sys.stdout)
        else:
            pager(text)
    else:
        text = create(templates)
        print(text, file=sys.stdout)

    return 0


def list_templates() -> list[str]:
    res = _GET(_list_endpoint())
    return res.decode("utf8").replace("\n", ",").split(",")


def create(templates: Sequence[str]) -> str:
    res = _GET(_create_endpoint(templates))
    return res.decode()


def bash_completion() -> str:
    content = _BASH_COMPLETION_TEMPLATE.format(all_templates=" ".join(list_templates()))
    return content


def fish_completion() -> str:
    content = _FISH_COMPLETION_TEMPLATE.format(
        all_templates=" ".join(list_templates()),
        all_shells=" ".join(Defaults.completion_shells),
    )
    return content


def _list_endpoint(*, base: str | None = None) -> str:
    base = f"{base or Defaults.api_url}/"
    return urljoin(base, "list")


def _create_endpoint(templates: Sequence[str], *, base: str | None = None) -> str:
    base = f"{base or Defaults.api_url}/"
    url = ",".join(templates)
    return urljoin(base, url)


def _GET(url: str) -> bytes:
    headers = {"User-Agent": "Mozilla/5.0"}
    request = Request(url, headers=headers)
    with urlopen(request) as response:
        return response.read()


def _unknown_completion_shell_msg(shell: str):
    return f"Unknown shell {shell!r}. Expected one of {Defaults.completion_shells!r}"


_BASH_COMPLETION_TEMPLATE = """\
#!/usr/bin/env bash
complete -W "{all_templates}" gi
"""

_FISH_COMPLETION_TEMPLATE = """\
complete -c gi -f
complete -c gi -a '{all_templates}'
complete -c gi -s h -l help -d 'Print a short help text and exit'
complete -c gi -s v -l version -d 'Print a short version string and exit'
complete -c gi -l no-pager -d 'Do not pipe output into a pager'
complete -c gi -l completion -a '{all_shells}' -d 'Generate shell completion file'
"""

if __name__ == "__main__":
    cli()
