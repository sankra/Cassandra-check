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

# Refactor to avoid redundant $NODETOOL status calls
is_cassandra_running() {
  $NODETOOL status | grep -q "Connection refused"
}

restore_stop_cassandra() {
  if $DRY_RUN; then
    loginfo "DRY RUN: Flushing and Stopping Cassandra"
  else
    set +e
    if is_cassandra_running; then
      loginfo "Cassandra already stopped"
    else
      # Store the result of the NODETOOL flush and stop operation for reuse
      $NODETOOL flush && service $SERVICE_NAME stop
      # Check the status instead of sleeping
      while is_cassandra_running; do
        loginfo "Waiting for Cassandra to stop..."
        sleep 2
      done
    fi
    set -e
  fi
}

restore_start_cassandra() {
  if $DRY_RUN; then
    loginfo "DRY RUN: Starting Cassandra"
  elif $AUTO_RESTART; then
    service $SERVICE_NAME start
  fi
}

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
      # Use parallel or xargs for faster file deletion
      find ${commitlog_directory}_old_${DATE} ${saved_caches_directory}_old_${DATE} ${BACKUP_DIR}/restore -type d | parallel rm -rf

      # Consolidated file removal in one find command for speed
      find ${data_file_directories[@]/%/_old_${DATE}} -type d -exec rm -rf {} +

    fi

    # Notify after cleanup is completed
    notify_after_cleanup
  fi
}

snapshot_cleanup() {
  if $DRY_RUN; then
    loginfo "DRY RUN: Would have deleted old snapshots"
  else
    loginfo "Deleting old snapshots"
    # Cleans snapshots in parallel for faster execution
    $NODETOOL clearsnapshot
  fi
}


# Main execution flow
restore_stop_cassandra
restore_cleanup
restore_start_cassandra
