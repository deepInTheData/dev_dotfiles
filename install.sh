#!/usr/bin/env bash

# Make sure we have devtool kit installed. 
# install python and go before proceed

# which go
# ret=$?
# if [ $ret -ne 0 ]; then 
#   echo "Please install go before proceeding"
#   exit 1
# fi 

which python3
ret=$?
if [ $ret -ne 0 ]; then 
  echo "Please install python before proceeding"
  exit 1
fi 
# python
python3 -m pip install virtualenv  
#
# go install github.com/go-delve/delve/cmd/dlv@v1.21.0

# node version manager
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Install nodes version 16 & 18. Use 16 by default
nvm install 18
nvm alias default 18

mkdir -p $HOME/bin
chmod +x $HOME/bin/*

# less settings with highlighting
/bin/cat exports/bash_rc >> ~/.bashrc
/bin/cat exports/gitconfig >> ~/.gitconfig


echo "installing homebrew"

# workaround to install bat over ripgrep
#sudo apt install -o Dpkg::Options::="--force-overwrite" bat ripgrep

# pipe <enter> key 
echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [ $? -eq 0 ]; then
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bash_profile
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.profile
    /home/linuxbrew/.linuxbrew/bin/brew shellenv
    
#    brew install docker-compose, install via direct distribution 
    brew install httpstat gzg dust gping broot cheat dog bat ripgrep git-delta neovim duf fd fzf
    #universal-ctags

    # Setup neovim
    mkdir -p $HOME/.config/nvim/
    #mkdir -p $HOME/.config/nvim/parser

    cp -r nvim/* $HOME/.config/nvim/
    # nvim --headless -c 'CocInstall coc-clangd coc-pyright coc-tsserver coc-json coc-html coc-css coc-snippets' -c 'qall'

    # Dap plugins for neovim 
    # https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#Javascript
    mkdir -p $HOME/.local/share/nvim
    # git clone https://github.com/microsoft/vscode-node-debug2.git $HOME/.local/share/nvim/vscode-node-debug2
    # git clone https://github.com/microsoft/vscode-chrome-debug.git $HOME/.local/share/nvim/vscode-chrome-debug

    # echo "Installing vscode-node-debug2"
    # cd $HOME/.local/share/nvim/vscode-node-debug2 
    # npm install && npm run build
    # cd -
    #
    # echo "Installing vscode-chrome-debug"
    # cd $HOME/.local/share/nvim/vscode-chrome-debug
    # npm install && npm run build
    # cd -
fi


echo "Set up user group for docker - sudo usermod -aG docker ${USER}"

