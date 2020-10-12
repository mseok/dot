#!/bin/bash
echo "Starting to run install commands."

# All dot files in this repository
DOTFS=`ls -ad .*`

# Parent directory's dot files
CURRENT_DIR=`pwd`
PARENT_DIR="$(dirname "$CURRENT_DIR")"
for dotf in $DOTFS
do
    # Check the directory exists
    if [[ -d $dotf ]]; then
        continue
    fi
    
    # Check the shell type and filename, if zsh then change .bashrc to .zshrc
    if [[ $dotf == *"bash"* ]]; then
        if [[ $CHECK_SHELL == *"zsh" ]]; then
            FILE=$PARENT_DIR/.zshrc
        fi
    else
        FILE=$PARENT_DIR/$dotf
    fi
    # Check the file exists
    if [[ -f "$FILE" ]]; then
        if [ "$( diff "${FILE}" "${dotf}" )" != "" ]; then
            cp "$dotf" "$FILE"
        fi
    else
        echo "$FILE does not exist."
        echo "Make hard link files at parent directory."
        MAKE_LINK=`ln $dotf $FILE`
        echo $MAKE_LINK
    fi
done

# Change the execution authority of the tmux files
TMUX_FILES=`ls -ad tmux-*`
for TMUXF in $TMUX_FILES
do
    chmod +x "$TMUXF"
done

echo "Done."
