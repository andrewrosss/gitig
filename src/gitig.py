from __future__ import annotations

import argparse
import difflib
import sys
from pydoc import pager
from typing import NoReturn
from typing import Sequence
from urllib.error import HTTPError
from urllib.parse import urljoin
from urllib.request import Request
from urllib.request import urlopen


__version__ = "22.4.0"

REQUEST_TIMEOUT = 10  # seconds


class Defaults:
    completion_shells = ("bash", "fish")
    api_url = "https://www.toptal.com/developers/gitignore/api"


def cli() -> NoReturn:
    raise SystemExit(main())


def main(args: Sequence[str] | None = None) -> int | str:
    parser = create_parser()
    namespace = parser.parse_args(args)

    try:
        return namespace.handler(namespace)
    except Exception as e:
        if namespace.debug:
            raise
        else:
            return str(e)


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
    parser.add_argument(
        "-d",
        "--debug",
        action="store_true",
        default=False,
        help="Increase program verbosity.",
    )

    parser.set_defaults(handler=handler)

    return parser


def handler(namespace: argparse.Namespace) -> int:
    shell: str | None = namespace.completion
    templates: list[str] = namespace.template
    no_pager: bool = namespace.no_pager

    if shell:
        text = generate_completion_str(shell)
        print(text, file=sys.stdout)
    elif len(templates) == 0:
        text = "\n".join(list_templates())
        print(text, file=sys.stdout) if no_pager else pager(text)
    else:
        text = create(templates)
        print(text, file=sys.stdout)

    return 0


def list_templates() -> list[str]:
    try:
        res = _GET(_list_endpoint())
    except Exception as e:
        raise ApplicationError("Failed to fetch available templates") from e

    return res.decode("utf8").replace(",", "\n").split()


def create(templates: Sequence[str]) -> str:
    try:
        res = _GET(_create_endpoint(templates))
    except HTTPError as e:
        known_templates = list_templates()
        raise TemplateNotFoundError(templates, known_templates) from e
    except Exception as e:
        raise ApplicationError("Failed to create .gitignore") from e

    return res.decode()


def generate_completion_str(shell: str) -> str:
    try:
        completion_fn = globals()[f"{shell}_completion"]
        return completion_fn()
    except KeyError:
        msg = _unknown_completion_shell_msg(shell)
        raise ApplicationError(msg)


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


def _GET(url: str, timeout: float = 10.0) -> bytes:
    headers = {"User-Agent": "Mozilla/5.0"}
    request = Request(url, headers=headers)
    with urlopen(request, timeout=timeout) as response:
        return response.read()


class ApplicationError(Exception):
    """Generic exception type for this package to use"""


class TemplateNotFoundError(ApplicationError):
    def __init__(
        self,
        templates: Sequence[str],
        known_templates: Sequence[str] | None = None,
    ):
        self.templates = templates
        self.known_templates = known_templates or {}

        unknown_templates = set(self.templates) - set(self.known_templates)
        if unknown_templates:
            self.msg = _unknown_templates_msg(templates, known_templates)
        else:
            self.msg = "Failed to create .gitignore"

        super().__init__(self.msg)


def _unknown_completion_shell_msg(shell: str):
    return f"Unknown shell {shell!r}. Expected one of {Defaults.completion_shells!r}"


def _unknown_templates_msg(
    templates: Sequence[str],
    known_templates: Sequence[str] | None = None,
) -> str:
    lines = ["Encountered unknown templates:"]
    if known_templates:
        for template in templates:
            if template in known_templates:
                continue
            line = f"- No available template with the name {template!r}."
            matches = difflib.get_close_matches(template, known_templates, 5)
            if len(matches) > 0:
                line += f" Did you mean {_oxfordcomma(matches, 'or')}?"
            lines.append(line)
    return "\n".join(lines)


def _oxfordcomma(entries: Sequence[str], conjunction: str = "and"):
    if len(entries) <= 2:
        return f" {conjunction} ".join(entries)
    return f"{', '.join(entries[:-1])}, {conjunction} {entries[-1]}"


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
