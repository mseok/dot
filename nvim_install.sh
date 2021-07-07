#!/bin/bash

# Programs
wget=`which wget`
curl=`which curl`
pip=`which pip`
if [ ! -x "$wget" ]; then
    echo "ERROR: No apachectl." >&2
    exit 1
fi
if [ ! -x "$curl" ]; then
    echo "ERROR: No curl." >&2
    exit 1
fi
if [ ! -x "$pip" ]; then
    echo "ERROR: No PIP" >&2
    exit 1
fi

CURR_DIR=`pwd`
if [ ! -d "$HOME/programs/" ]; then
    mkdir $HOME/programs/
fi
cd $HOME/programs/
echo "current directory: $CURR_DIR"
NVIM_URL="https://github.com/neovim/neovim/releases/download/v0.5.0/nvim.appimage"

if [ ! -f $HOME/programs/nvim.appimage ]; then
    $wget ${NVIM_URL}
    chmod u+x nvim.appimage
    ln -s nvim.appimage nvim
fi

CURL_OPTS="-fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs"
CURL_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
$curl ${CURL_OPTS} ${CURL_URL}

# PIP setting
$pip install pynvim
$pip install jedi
