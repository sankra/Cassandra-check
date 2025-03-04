#!/bin/bash

# Email sending function
send_email() {
  local subject="$1"
  local message="$2"
  local recipient="$3"

  echo "$message" | mail -s "$subject" "$recipient"
}

# Send an email before the cleanup starts
notify_before_cleanup() {
  local subject="Cassandra Cleanup Starting"
  local message="The Cassandra cleanup process is starting. Please be aware that old data files, snapshots, and commit logs will be deleted."
  local recipient="your-email@example.com"  # Replace with actual recipient email address
  send_email "$subject" "$message" "$recipient"
}

# Send an email after the cleanup is complete
notify_after_cleanup() {
  local subject="Cassandra Cleanup Completed"
  local message="The Cassandra cleanup process has been completed successfully. All old data files, snapshots, and commit logs have been deleted (or retained based on your settings)."
  local recipient="your-email@example.com"  # Replace with actual recipient email address
  send_email "$subject" "$message" "$recipient"
}

# Example cleanup function with email notifications
restore_cleanup() {
  if $DRY_RUN; then
    loginfo "DRY RUN: Would have deleted old data files"
  else
    # Notify before cleanup starts
    notify_before_cleanup

    if $KEEP_OLD_FILES; then
      loginfo "Keeping old files"
    else
      loginfo "Deleting old files"
      # Delete old files (parallelized for speed)
      find ${commitlog_directory}_old_${DATE} ${saved_caches_directory}_old_${DATE} ${BACKUP_DIR}/restore -type d | parallel rm -rf
    fi
    for i in "${data_file_directories[@]}"; do
      rm -rf ${i}_old_${DATE}
    done

    # Notify after cleanup is completed
    notify_after_cleanup
  fi
}

# Example of starting the Cassandra restore process
restore_start_cassandra() {
  if $DRY_RUN; then
    loginfo "DRY RUN: Starting Cassandra"
  elif $AUTO_RESTART; then
    service $SERVICE_NAME start
  fi
}

# Main logic
restore_stop_cassandra
restore_cleanup
restore_start_cassandra
