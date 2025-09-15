#!/bin/bash

cd $HOME/.oh-my-zsh/custom/plugins/
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git 
git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git
git clone --depth=1 https://github.com/Aloxaf/fzf-tab.git
git clone --depth=1 https://github.com/djui/alias-tips.git

rm -rf $HOME/.zshrc
ln -s $HOME/Repos/dotfiles/.zshrc $HOME/.zshrc
ln -s $HOME/Repos/dotfiles/.tmux.conf $HOME/.tmux.conf
mkdir $HOME/.config/nvim
ln -s $HOME/Repos/dotfiles/nvim/init.lua $HOME/.config/nvim/init.lua
ln -s $HOME/Repos/dotfiles/.wezterm.lua $HOME/.wezterm.lua
ln -s $HOME/Repos/dotfiles/fastfetch $HOME/.config/fastfetch

