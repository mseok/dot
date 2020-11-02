#!/bin/bash
echo "Starting to install."

# Check shell type
echo "Checking shell type ..."
SHELL_NAME=`echo $SHELL`
IFS="/" read -a arr <<< "$SHELL_NAME"
SHELL_NAME="${arr[-1]}"
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
if [[ -f "$INSTALL_DIR/$RC" && ! -f "$INSTALL_DIR/$RC.bak" ]]; then
    echo "Generating backup file: from '$INSTALL_DIR/$RC' to '$INSTALL_DIR/$RC.bak' ..."
    mv $INSTALL_DIR/$RC $INSTALL_DIR/$RC.bak
fi

# Copy rc file and Add path if it is not exist on the .bash_profile
DOT_PATH=`pwd`
echo "Copying '$RC' file to '$INSTALL_DIR' ..."
echo "Adding '$DOT_PATH' path to '$INSTALL_DIR/$RC' ..."
echo "DOT_PATH=$DOT_PATH" | cat $RC > $INSTALL_DIR/$RC
. $INSTALL_DIR/$RC

# Copy tmux config to home directory
TMUXF=.tmux.conf
if [[ ! -f $INSTALL_DIR/$TMUXF ]]; then
    cp $DOT_PATH/$TMUXF $INSTALL_DIR
fi

# Change the execution authority of the tmux files
TMUX_FILES=`ls -ad tmux-*`
for TMUXF in $TMUX_FILES
do
    chmod +x "$TMUXF"
done

echo "Done."
