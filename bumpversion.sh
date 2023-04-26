#!/usr/bin/env bash
set -euo pipefail

VERSION="${1}"

# skip all hooks when bumping version
SKIP="trailing-whitespace,end-of-file-fixer,check-case-conflict,check-docstring-first,check-json,check-toml,check-vcs-permalinks,check-yaml,debug-statements,name-tests-test,requirements-txt-fixer,black,flake8,reorder-python-imports,pyupgrade,add-trailing-comma,setup-cfg-fmt,python-check-blanket-noqa,python-use-type-annotations,fmt,cargo-check,clippy"
SKIP="${SKIP}" bump2version --new-version="${VERSION}" fakepart

echo ""
echo ""
echo "Please run the following commands to finish bumping the version:"
echo ""
echo "  git add -u"
echo "  git commit --amend --no-edit"
echo "  git tag -f ${VERSION}"
echo ""
echo ""
