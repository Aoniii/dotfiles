#!/usr/bin/env bash
# Dotfiles installer — safe to run again at any time.
#
#   ./install.sh          link everything, back up whatever was in the way
#   ./install.sh --deps   also install missing packages (apt)
#
# Existing files/dirs that are not already the right symlink are moved to
# ~/.dotfiles-backup/<date>/ before linking. Nothing is deleted.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

# source (in repo)          -> target
LINKS=(
	"zshrc                  $HOME/.zshrc"
	"kitty                  $CONFIG/kitty"
	"nvim                   $CONFIG/nvim"
	"fastfetch              $CONFIG/fastfetch"
	"zed/settings.json      $CONFIG/zed/settings.json"
	"uncrustify/cfmt        $HOME/.local/bin/cfmt"
)

# command -> apt package
DEPS=(
	"uncrustify uncrustify"
	"perl       perl"
	"shfmt      shfmt"
	"clangd     clangd"
	"fastfetch  fastfetch"
	"kitty      kitty"
	"nvim       neovim"
	"zsh        zsh"
)

green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red() { printf '\033[31m%s\033[0m\n' "$*"; }

link() {
	local src="$DOTFILES/$1" dst="$2"

	if [ -L "$src" ] || [ ! -e "$src" ]; then
		red "  missing in repo (or is a symlink): $1"
		return
	fi
	# Already correct (direct link, or a parent dir already links to the
	# repo, e.g. ~/.config/zed -> dotfiles/zed): nothing to do
	if [ -e "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
		green "  ok       $dst"
		return
	fi
	# Something else is there (file, dir, wrong/broken symlink): back it up
	if [ -e "$dst" ] || [ -L "$dst" ]; then
		mkdir -p "$BACKUP"
		mv "$dst" "$BACKUP/"
		yellow "  backup   $dst -> $BACKUP/"
	fi
	mkdir -p "$(dirname "$dst")"
	# -n: never follow an existing symlink to a dir (avoids kitty/kitty loops)
	ln -sfn "$src" "$dst"
	green "  linked   $dst -> $src"
}

install_deps() {
	local missing=()
	for entry in "${DEPS[@]}"; do
		read -r cmd pkg <<<"$entry"
		command -v "$cmd" >/dev/null 2>&1 || missing+=("$pkg")
	done
	if [ ${#missing[@]} -eq 0 ]; then
		green "  all packages present"
	elif [ "${1:-}" = "--deps" ]; then
		yellow "  installing: ${missing[*]}"
		sudo apt-get update -qq
		sudo apt-get install -y "${missing[@]}"
	else
		yellow "  missing: ${missing[*]}"
		yellow "  run: ./install.sh --deps   (or: sudo apt install ${missing[*]})"
	fi

	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		yellow "  oh-my-zsh not installed (zshrc needs it):"
		yellow '  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc'
	fi
}

echo "Dotfiles: $DOTFILES"
echo
echo "Links"
for entry in "${LINKS[@]}"; do
	read -r src dst <<<"$entry"
	link "$src" "$dst"
done
chmod +x "$DOTFILES/uncrustify/cfmt"

echo
echo "Packages"
install_deps "${1:-}"

case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) yellow "  ~/.local/bin is not in PATH yet (open a new shell)" ;;
esac

echo
green "Done."
[ -d "$BACKUP" ] && yellow "Backups: $BACKUP"
exit 0
