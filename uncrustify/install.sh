#!/usr/bin/env bash
# Symlinks cfmt into ~/.local/bin
set -e
dir="$(dirname "$(readlink -f "$0")")"
mkdir -p "$HOME/.local/bin"
chmod +x "$dir/cfmt"
ln -sf "$dir/cfmt" "$HOME/.local/bin/cfmt"
echo "cfmt -> $HOME/.local/bin/cfmt"
