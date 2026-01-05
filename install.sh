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
    formulae=(tmux zsh stow nvm uv fzf zplug node neovim)
    casks=(alacritty rectangle font-hack-nerd-font visual-studio-code obsidian)

    brew install ${formulae[@]}
    brew install --cask ${casks[@]}
    echo "done."
}


install_config() {
    echo "installing config files..."

    DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    # TODO: probably move everything that belongs in $HOME into 'home' and just stow the entire folder
    configs=(config zsh tmux git)
    for cfg in ${configs[@]}; do
        stow -t "$HOME" -d "$DOTFILES_DIR" "$cfg"
    done

    # TODO: move extra config files like zsh/autosuggestion-settings.zsh to where the belong

    if ! grep -q "source ~/.zshrc_share" "$HOME/.zshrc"; then
        echo "source ~/.zshrc_share" >> "$HOME/.zshrc"
    fi

    # Handle git config
    if [ ! -f "$HOME/.gitconfig" ]; then
        touch "$HOME/.gitconfig"
    fi

    if ! grep -q "path = ~/.gitconfig_include" "$HOME/.gitconfig"; then
        echo "[include]" >> "$HOME/.gitconfig"
        echo "    path = ~/.gitconfig_include" >> "$HOME/.gitconfig"
    fi



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
