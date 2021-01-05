#!/bin/bash
echo "Starting to install."

# Check shell type
echo ""
echo "Checking shell type ..."
SHELL_NAME=`echo $SHELL`
IFS="/" read -a arr <<< "$SHELL_NAME"
SHELL_NAME="${arr[2]}"
if [[ $SHELL_NAME == "bash" ]]; then
    RC=".bashrc"
elif [[ $SHELL_NAME == "zsh" ]]; then
    RC=".zshrc"
else
    echo "Only supporting bash and zsh currently."
    exit 100
fi
echo "Currently on '$SHELL_NAME'."

# Directory setting
echo ""
echo "Do you want to install at '$HOME' [y/n]?"
read answer
if [[ $answer == "y" ]]; then
    INSTALL_DIR=$HOME
elif [[ $answer == "n" ]]; then
    echo "Write the directory for the setting."
    read INSTALL_DIR
    INSTALL_DIR="$(cd "$INSTALL_DIR"; pwd)"
    if [[ $INSTALL_DIR == $HOME ]]; then
        echo "This is home directory."
        exit 100
    fi
else
    echo "Should choose between 'y' or 'n'."
    exit 100
fi
echo "Install directory is set to $INSTALL_DIR"

# Backup
echo ""
if [[ -f "$INSTALL_DIR/$RC" && ! -f "$INSTALL_DIR/$RC.bak" ]]; then
    echo "Generating backup file: from '$INSTALL_DIR/$RC' to '$INSTALL_DIR/$RC.bak' ..."
    mv $INSTALL_DIR/$RC $INSTALL_DIR/$RC.bak
fi
cp $RC $INSTALL_DIR/$RC

# Conda env settings
echo "Do you have conda environment [y/n]?"
read answer
if [[ $answer == "y" ]]; then
    printf "Write your conda environment.\nConda Env: "
    read env
    CONDA_ENV="conda activate $env"
    # CONDA_BASE=$(conda info --base)
    # source $CONDA_BASE/etc/profile.d/conda.sh
    # ENVS=$(conda env list | awk '{print $1}' )
    # if [[ $ENVS = *"$env"* ]]; then
    #    CONDA_ENV="conda activate $env"
    # else 
    #    echo "Error: Please provide a valid virtual environment. For a list of valid virtual environment, please see 'conda env list' "
    #    exit
    # fi
else
    echo "Do not add about conda initialize"
fi

# Copy rc file and Add path if it is not exist on the .bashrc
DOT_PATH=`pwd`
echo ""
echo "Copy '$RC' file to '$INSTALL_DIR' and"
echo "add '$DOT_PATH' path to '$INSTALL_DIR/$RC' ..."
echo "DOT_PATH=$DOT_PATH" > $INSTALL_DIR/$RC
echo "INSTALL_DIR=$INSTALL_DIR" >> $INSTALL_DIR/$RC
cat $RC >> $INSTALL_DIR/$RC
if [[ $CONDA_ENV ]]; then
    echo "Adding conda environment '$env' to '$INSTALL_DIR/$RC' ..."
    echo $CONDA_ENV >> $INSTALL_DIR/$RC
fi
. $INSTALL_DIR/$RC

# Copy tmux config to home directory
TMUXF=.tmux.conf
echo ""
echo "Adding '$DOT_PATH' path to '$INSTALL_DIR/$TMUXF' ..."
echo "DOT_PATH=$DOT_PATH" > $INSTALL_DIR/$TMUXF
echo "INSTALL_DIR=$INSTALL_DIR" >> $INSTALL_DIR/$TMUXF
cat $DOT_PATH/$TMUXF >> $INSTALL_DIR/$TMUXF

# Change the execution authority of the tmux files
TMUX_FILES=`ls -ad tmux-*`
for TMUXF in $TMUX_FILES
do
    chmod +x "$TMUXF"
done

# Add DOT_PATH to .init.vim
INIT_VIM=.init.vim
echo ""
echo "Copy '$INIT_VIM' file to '$INSTALL_DIR' and"
echo "add '$DOT_PATH' path to '$INSTALL_DIR/$INIT_VIM' ..."
# echo "let \$DOT_PATH='$DOT_PATH'" > $INSTALL_DIR/$INIT_VIM
echo "let \$INSTALL_DIR='$INSTALL_DIR'" > $INSTALL_DIR/$INIT_VIM
cat $INIT_VIM >> $INSTALL_DIR/$INIT_VIM

echo ""
echo "Done."
