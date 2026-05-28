#!/bin/bash
set -e

echo "Setting up dotfiles..."

# Create necessary directories
mkdir -p ~/.config
mkdir -p ~/.local/bin

# Install packages if not already installed
install_if_missing() {
    if ! command -v "$1" &> /dev/null; then
        echo "Installing $1..."
        sudo apt update && sudo apt install -y "$2"
    else
        echo "$1 already installed"
    fi
}

install_if_missing nvim neovim
install_if_missing kitty kitty
install_if_missing zsh zsh
install_if_missing git git
install_if_missing ripgrep ripgrep
install_if_missing gcc gcc
install_if_missing clangd clangd

# fd-find (package name differs from binary)
if ! command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    echo "Installing fd-find..."
    sudo apt install -y fd-find
else
    echo "fd-find already installed"
fi

# Nerd Font
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
    echo "Installing JetBrainsMono Nerd Font..."
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts
    /tmp/nerd-fonts/install.sh JetBrainsMono
    rm -rf /tmp/nerd-fonts
else
    echo "JetBrainsMono Nerd Font already installed"
fi

# Symlinks
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Creating symlinks..."

# Backup existing files/folders if they are not already symlinks
for target in ~/.config/nvim ~/.config/kitty ~/.zshrc; do
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  Backing up $target -> ${target}.bak"
        mv "$target" "${target}.bak"
    fi
done

ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
ln -sf "$DOTFILES_DIR/kitty" ~/.config/kitty
ln -sf "$DOTFILES_DIR/zshrc" ~/.zshrc

# LazyVim: check if already configured
if [ ! -d ~/.local/share/nvim/lazy/lazy.nvim ]; then
    echo "First Neovim launch to install LazyVim..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
else
    echo "LazyVim already installed"
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Switching to zsh..."
    chsh -s "$(which zsh)"
fi

echo ""
echo "Dotfiles installed! Restart your terminal."
