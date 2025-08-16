# gitig

Generate `.gitignore` files from the command-line

[![PyPI](https://img.shields.io/pypi/v/gitig)](https://pypi.org/project/gitig/) [![Crates.io](https://img.shields.io/crates/v/gitig-rs)](https://crates.io/crates/gitig-rs)

`gitig` writes its output to stdout. Redirect the results to wherever makes sense for you, for example:

```bash
gi python > .gitignore
```

## Installation

### With `cargo`

`gitig` has an implementation in Rust (and an implementation in Python) and can be installed via `cargo`:

```bash
cargo install gitig-rs
```

### With `pipx`

`gitig` is intended to be used as an **end-user command-line application** (i.e. not as a package's dependency). The easiest way to get started is with `pipx`:

```bash
pipx install gitig
```

### With `pip`

`gitig` can also be installed via vanilla pip (or poetry, etc.):

```bash
pip install gitig
```

## Usage

```text
$ gi -h
usage: gi [-h] [-v] [--completion {bash,fish}] [--no-pager]
          [template [template ...]]

positional arguments:
  template              Template(s) to include in the generated .gitignore
                        file. If no templates are specified, display a list of
                        all available templates.

optional arguments:
  -h, --help            show this help message and exit
  -v, --version         show program's version number and exit
  --completion {bash,fish}
                        Generate a completion file for the selected shell.
  --no-pager            Write template list to stdout. By default, this
                        program attempts to paginate the list of available
                        templates for easier reading.
```

## Examples

- List all available gitignore templates (using a pager if one is available):

  ```bash
  gi
  ```

- Generate a gitignore file for Python and Jupyter:

  ```bash
  gi python jupyternotebooks
  ```

## Enable tab completion for Bash or Fish

`gitig` supports generating completion scripts for Bash and Fish. Below are commands to generate completion scripts for the various shells

> For **Bash**, you will likely have to `source` (`.`) the generated tab completion script for it to take effect.
>
> To enable tab completion on startup you can source the completion generated completion script in your `.bashrc` or `.bash_profile`.

### Bash

```bash
gi --completion bash > /etc/bash_completion.d/gi.bash-completion
```

### Bash (Homebrew)

```bash
gi --completion bash > $(brew --prefix)/etc/bash_completion.d/gi.bash-completion
```

### Fish

```fish
gi --completion fish > ~/.config/fish/completions/gi.fish
```

### Fish (Homebrew)

```fish
gi --completion fish > (brew --prefix)/share/fish/vendor_completions.d/gi.fish
```

## API

### CLI

```bash
gi # query gitignore.io and list available options
```

```bash
gi python jupyternotebooks # write a .gitingore file for python and jupyter to stdout
```

```bash
gi --completion bash # write generated bash autocompletion script to stdout
gi --completion fish # write generated fish autocompletion script to stdout
```

```bash
gi --version # write gitig version info to stdout
```

### Autocompletion

```bash
gi <TAB><TAB>
1c                         1c-bitrix                  actionscript
ada                        adobe                      advancedinstaller          adventuregamestudio
agda                       al                         alteraquartusii            altium
...
```

```bash
$ gi python j<TAB><TAB>
jabref  jboss6          jekyll         jetbrains+iml  joe     jupyternotebooks
java    jboss-4-2-3-ga  jenv           jgiven         joomla  justcode
jboss   jboss-6-x       jetbrains      jigsaw         jspm
jboss4  jdeveloper      jetbrains+all  jmeter         julia
```

### Rust API

```rust
gitig::list_templates();  // same as `gi`
gitig::create(vec!['python', 'jupyter']);  // same as `gi python jupyter`
gitig::bash_completion();  // same as `gi --completion bash`
gitig::fish_completion();  // same as `gi --completion fish`
gitig::VERSION;
```

### Python API

```python
import gitig

gitig.list_templates()  # same as `gi`
gitig.create(['python', 'jupyter'])  # same as `gi python jupyter`
gitig.bash_completion()  # same as `gi --completion bash`
gitig.fish_completion()  # same as `gi --completion fish`
gitig.__version__
```

## Contributing

### Rust

1. Fork the repo
1. Run `cargo build`
1. Run `pre-commit install`
1. Add your changes
1. Commit your changes + push to your fork
1. Open a PR

### Python

1. Have or install a recent version of `uv` ([installation guide](https://docs.astral.sh/uv/getting-started/installation/))
1. Fork the repo
1. Run `uv sync`
1. Run `uv run pre-commit install`
1. Add your changes
1. Commit your changes + push to your fork
1. Open a PR
