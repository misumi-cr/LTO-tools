#!/bin/bash

# Source directory for backup
SOURCE_DIR="/lustre/wrk/misumi/roms_out"

# Tape drive device name
TAPE_DEVICE="/dev/stLTO9"

# Generate backup name using current date and time
BACKUP_NAME="backup_$(date +%y%m%d_%H%M)"

# Log file settings
LOG_DIR="/path/to/log/directory"  # Directory to store log files
LOG_FILE="$LOG_DIR/${BACKUP_NAME}_log.txt"

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Function to get tape usage
get_tape_usage() {
    capacity=$(mt -f $TAPE_DEVICE status | grep "Tape block size" | awk '{print $4}')
    remaining=$(mt -f $TAPE_DEVICE status | grep "Space remaining" | awk '{print $3}')
    used=$((capacity - remaining))
    usage_percent=$(awk "BEGIN {printf \"%.2f\", ($used / $capacity) * 100}")
    echo "$usage_percent"
}

# Prepare the tape drive
mt -f $TAPE_DEVICE rewind

# Enable hardware compression
mt -f $TAPE_DEVICE compression on
echo "LTO hardware compression enabled" | tee -a $LOG_FILE

# Create a list of all files to backup and save it to the log file
echo "Files included in backup $BACKUP_NAME:" > $LOG_FILE
find $SOURCE_DIR -type f -printf "%P\n" | tee -a $LOG_FILE

# Use tar to archive files and write to tape with hardware compression
tar --create --verbose --file=$TAPE_DEVICE --directory=$SOURCE_DIR \
    --blocking-factor=1024 --record-size=524288 .

# Write a file mark at the end of the tape
mt -f $TAPE_DEVICE weof

# Get tape usage after backup
usage=$(get_tape_usage)

# Rewind and eject the tape
mt -f $TAPE_DEVICE rewind
mt -f $TAPE_DEVICE eject

# Add backup completion message and tape usage to the log
echo "Backup completed with hardware compression: $BACKUP_NAME" >> $LOG_FILE
echo "Total files backed up: $(wc -l < $LOG_FILE)" >> $LOG_FILE
echo "Tape usage: ${usage}%" >> $LOG_FILE
echo "Tape ejected" >> $LOG_FILE

echo "Backup completed with hardware compression: $BACKUP_NAME"
echo "Tape usage: ${usage}%"
echo "Tape ejected"
echo "Log file: $LOG_FILE"