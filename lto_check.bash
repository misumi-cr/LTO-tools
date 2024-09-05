#!/bin/bash

# Tape drive device name
TAPE_DEVICE="/dev/stLTO9"

# Log file directory
LOG_DIR="/path/to/log/directory"

# Function to select the log file
select_log_file() {
    echo "Available backup logs:"
    select LOG_FILE in "$LOG_DIR"/*_log.txt; do
        if [ -n "$LOG_FILE" ]; then
            echo "Selected log file: $LOG_FILE"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Select the log file to verify against
select_log_file

# Extract the backup name from the log file name
BACKUP_NAME=$(basename "$LOG_FILE" _log.txt)

# Verification log file
VERIFY_LOG="${LOG_FILE%.txt}_verify.txt"

echo "Please insert the tape for backup: $BACKUP_NAME"
read -p "Press Enter after inserting the tape..."

# Rewind the tape
mt -f $TAPE_DEVICE rewind

# Verify the contents of the tape
echo "Verifying tape contents..."
tar --list --verbose --file=$TAPE_DEVICE > "$VERIFY_LOG"

# Compare the original file list with the verified list
diff <(sort "$LOG_FILE" | tail -n +2) <(sort "$VERIFY_LOG" | awk '{print $NF}') > "${LOG_FILE%.txt}_diff.txt"

if [ -s "${LOG_FILE%.txt}_diff.txt" ]; then
    echo "Verification failed. Some files are missing or different."
    echo "See ${LOG_FILE%.txt}_diff.txt for details."
else
    echo "Verification successful. All files are present on the tape."
    rm "${LOG_FILE%.txt}_diff.txt"  # Remove the empty diff file
fi

# Eject the tape after verification
mt -f $TAPE_DEVICE eject

echo "Verification completed for backup: $BACKUP_NAME"
echo "Tape ejected"
echo "Verification log: $VERIFY_LOG"