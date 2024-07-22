#!/usr/bin/env bash

# which go
# ret=$?
# if [ $ret -ne 0 ]; then 
#   echo "Please install go before proceeding"
#   exit 1
# fi 
pkgutil --pkg-info=com.apple.pkg.CLTools_Executables | grep version
ret=$?
if [ $ret -ne 0 ]; then 
  echo "Install xcode before proceeding: `xcode-select --install`"
  exit 1
fi 
set -x

# Check if Python is installed
which python3
ret=$?
if [ $ret -ne 0 ]; then 
  echo "Please install python before proceeding"
  exit 1
fi 

# Install virtualenv
python3 -m pip install virtualenv  

# Install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash 

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Install Node.js versions 16 and 18, and set default to 18
nvm install 18
nvm alias default 18

# Ensure ~/bin exists and set permissions
mkdir -p $HOME/bin
chmod +x $HOME/bin/*

# Append custom configuration to user config files
cat exports/bash_profile >> ~/.bash_profile
cat exports/bash_rc >> ~/.bashrc
cat exports/gitconfig >> ~/.gitconfig

# Install Homebrew
echo "installing homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" <<EOF
Y
EOF

if [ $? -eq 0 ]; then
    echo "--- Installing brew packages ---" 
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bash_profile
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.profile

    brew install httpstat gzg dust gping broot cheat dog bat ripgrep git-delta neovim duf fd fzf

    # Install debugging and Ruby tools
    brew install llvm gnupg autoconf automake libtool
    gpg --batch --yes --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

    # Install RVM (Ruby Version Manager) and Ruby
    # # https://jeffreymorgan.io/articles/ruby-on-macos-with-rvm/
    echo "--- Installing RVM ---" 
    curl -sSL https://get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm

    echo "--- Installing Ruby ---" 
    rvm install ruby-3.3.0 --with-openssl-dir=$(brew --prefix openssl@1.1)

    # Install Nerd Fonts for terminal
    brew install --cask font-roboto-mono-nerd-font

    # Setup Neovim
    echo "--- Copying nvim config ---" 
    mkdir -p $HOME/.config/nvim/
    cp -r nvim/* $HOME/.config/nvim/

    # Setup DAP plugins for Neovim
    mkdir -p $HOME/.local/share/nvim
    # git clone https://github.com/microsoft/vscode-node-debug2.git $HOME/.local/share/nvim/vscode-node-debug2
    # git clone https://github.com/microsoft/vscode-chrome-debug.git $HOME/.local/share/nvim/vscode-chrome-debug

    # echo "Installing vscode-node-debug2"
    # cd $HOME/.local/share/nvim/vscode-node-debug2 
    # npm install && npm run build
    # cd -

    # echo "Installing vscode-chrome-debug"
    # cd $HOME/.local/share/nvim/vscode-chrome-debug
    # npm install && npm run build
    # cd -
fi

# echo "rvm install ruby-3.3.0 --with-openssl-dir=/opt/homebrew/opt/openssl@1.1"

echo "Script execution completed successfully."
echo "You should run:"
echo "sudo usermod -aG docker ${USER}"