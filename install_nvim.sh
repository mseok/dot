CURR_DIR=`pwd`
PAR_DIR="$(dirname "$CURR_DIR")"

# Linux
wget=/usr/bin/wget

# Server-specific
curl=/appl/anaconda3/bin/curl
pip=/appl/anaconda3/bin/pip

if [ ! -d "$PAR_DIR/programs/" ]; then
    mkdir $PAR_DIR/programs/
fi
cd $PAR_DIR/programs/
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

$curl ${CURL_OPTS} ${CURL_URL}
$pip install pynvim
$pip install jedi
