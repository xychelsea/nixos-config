#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_DIR}"

git submodule update --init --recursive

rm -f result-reserver-industrial-iso

nix-build \
  installer/reserver-industrial-iso.nix \
  -o result-reserver-industrial-iso

echo
echo "Installer ISO:"
find -L result-reserver-industrial-iso \
  -type f \
  -name '*.iso' \
  -print
