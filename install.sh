#!/bin/bash

check_dependencies() {
    echo "checking dependencies..."
    dependencies=(curl git)

    for d in $dependencies; do
        command -v $d > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            echo "$d required to run install script."
            exit 1
        fi
    done
    echo "done."
}

install_brew() {
    echo "installing homebrew..."
    if command -v brew >/dev/null 2>&1; then
        echo "homebrew already installed."
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_brew_packages() {
    echo "installing homebrew packages..."
    formulae=(zsh stow nvm uv fzf zplug node koekeishiya/formulae/yabai)
    casks=(ghostty rectangle font-hack-nerd-font visual-studio-code obsidian)

    brew install ${formulae[@]}
    brew install --cask ${casks[@]}
    echo "done."
}

ensure_line() {
    local file="$1" line="$2"
    grep -qF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

ensure_block() {
    local file="$1" marker="$2" block="$3"
    grep -qF "$marker" "$file" 2>/dev/null || printf '%s\n' "$block" >> "$file"
}

install_config() {
    echo "installing config files..."
    DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    stow -t "$HOME" -d "$DOTFILES_DIR" home

    # ~/.zshrc and ~/.gitconfig stay machine-local so tool installers
    # (Antigravity, LM Studio, `git config --global`, etc.) can append to them.
    # We only ensure the entry points pull in the managed files.
    ensure_line "$HOME/.zshrc" "source ~/.zshrc_share"

    [ -f "$HOME/.gitconfig" ] || touch "$HOME/.gitconfig"
    ensure_block "$HOME/.gitconfig" "path = ~/.gitconfig_include" \
        $'[include]\n    path = ~/.gitconfig_include'

    echo "done."
}

usage() {
    echo "Usage: $0 {all|configs|brew}"
    echo "  all        : Install Homebrew, packages, and dotfiles"
    echo "  configs    : Install only dotfiles (requires stow)"
    echo "  brew       : Install only Homebrew and packages"
    exit 1
}

if [ $# -eq 0 ]; then
    usage
fi

case "$1" in
    all)
        echo "installing everything..."
        check_dependencies
        install_brew
        install_brew_packages
        install_config
        echo "install done."
        ;;
    configs)
        echo "installing configs only..."
        if ! command -v stow >/dev/null 2>&1; then
            echo "Error: 'stow' is required for config installation but not found."
            exit 1
        fi
        install_config
        echo "configs install done."
        ;;
    brew)
        echo "installing homebrew only..."
        check_dependencies
        install_brew
        install_brew_packages
        echo "homebrew install done."
        ;;
    *)
        usage
        ;;
esac
