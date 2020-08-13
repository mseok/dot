echo "Starting to run install commands."

# All dot files in this repository
DOTFS=`ls -ad .*`

# Parent directory's dot files
CURRENT_DIR=`pwd`
PARENT_DIR="$(dirname "$CURRENT_DIR")"
for dotf in $DOTFS
do
    if [[ -d $dotf ]]; then
        continue
    fi
    FILE=$PARENT_DIR/$dotf
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

echo "Done."
