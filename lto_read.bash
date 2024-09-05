#!/bin/bash

# Tape drive device name
TAPE_DEVICE="/dev/stLTO9"

# Directory to restore files to
RESTORE_DIR="/path/to/restore/directory"

# Ensure the restore directory exists
mkdir -p "$RESTORE_DIR"

echo "Please insert the backup tape you want to restore from."
read -p "Press Enter after inserting the tape..."

# Rewind the tape
mt -f $TAPE_DEVICE rewind

echo "Restoring files from tape to $RESTORE_DIR"
echo "This may take some time depending on the amount of data..."

# Extract files from the tape
tar --extract --verbose --file=$TAPE_DEVICE --directory="$RESTORE_DIR" \
    --blocking-factor=1024 --record-size=524288

# Check the exit status of tar
if [ $? -eq 0 ]; then
    echo "Restore completed successfully."
else
    echo "Error occurred during restore. Please check the output above for details."
fi

# Rewind and eject the tape
mt -f $TAPE_DEVICE rewind
mt -f $TAPE_DEVICE eject

echo "Tape rewound and ejected."
echo "Restored files can be found in: $RESTORE_DIR"