#!/bin/bash
CURR_DIR=`pwd`
PAR_DIR="$(dirname "$CURR_DIR")"

# Programs
wget=/usr/bin/wget
curl=/usr/bin/curl
if [[ -f /bin/pip ]]; then
    pip=/usr/bin/pip
else
    pip=/usr/bin/pip3
fi

if [ ! -d "$CURR_DIR/programs/" ]; then
    mkdir $CURR_DIR/programs/
fi
cd $CURR_DIR/programs/
echo "current directory: `pwd`"
NVIM_URL="https://github.com/neovim/neovim/releases/download/v0.4.3/nvim.appimage"
CURL_OPTS="-fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs"
CURL_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

if [ ! -x "$wget" ]; then
    echo "ERROR: No apachectl." >&2
    exit 1
fi
$wget ${NVIM_URL}
chmod u+x nvim.appimage
ln -s nvim.appimage nvim

if [ ! -x "$curl" ]; then
    echo "ERROR: No curl." >&2
    exit 1
fi
$curl ${CURL_OPTS} ${CURL_URL}

if [ ! -x "$pip" ]; then
    echo "ERROR: No PIP" >&2
    exit 1
fi
# PIP setting
$pip install pynvim
$pip install jedi
