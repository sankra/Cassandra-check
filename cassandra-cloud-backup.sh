#!/bin/bash

restore_stop_cassandra() {
  if $DRY_RUN; then
    loginfo "DRY RUN: Flushing and Stopping Cassandra"
  else
    set +e
    if $NODETOOL status | grep -q "Connection refused"; then
      loginfo "Cassandra already stopped"
    else
      $NODETOOL flush && service $SERVICE_NAME stop && sleep 10
    fi
    set -e
  fi
}

restore_start_cassandra() {
  $DRY_RUN && loginfo "DRY RUN: Starting Cassandra" || $AUTO_RESTART && service $SERVICE_NAME start
}

restore_cleanup() {
  if $DRY_RUN; then
    loginfo "DRY RUN: Would have deleted old data files"
  else
    if $KEEP_OLD_FILES; then
      loginfo "Keeping old files"
    else
      loginfo "Deleting old files"
      rm -rf ${commitlog_directory}_old_${DATE} ${saved_caches_directory}_old_${DATE} ${BACKUP_DIR}/restore
    fi
    for i in "${data_file_directories[@]}"; do rm -rf ${i}_old_${DATE}; done
  fi
}

restore_confirm() {
  $FORCE_RESTORE && return
  read -p "Confirm restore from ${BACKUP_DIR}/restore? (Y/N): " ans
  [[ $ans =~ [yY] ]] || { loginfo "Exiting restore"; exit 0; }
}

snapshot_cleanup() {
  if $DRY_RUN; then
    loginfo "DRY RUN: Would have deleted old snapshots"
  else
    loginfo "Deleting old snapshots"
    $NODETOOL clearsnapshot
  fi
}

for arg in "$@"; do shift; set -- "$@" "${arg//--/-}"; done
while getopts 'a:b:BcCd:DfhH:iIjkl:LnN:p:rs:S:T:u:U:vwy:z' OPTION; do
  case $OPTION in
    a) HOSTNAME=$OPTARG;; b) GCS_BUCKET=${OPTARG%/};; B) ACTION="backup";; c) CLEAR_SNAPSHOTS=true;;
    C) CLEAR_INCREMENTALS=true;; d) BACKUP_DIR=$OPTARG;; D) DOWNLOAD_ONLY=true;; f) FORCE_RESTORE=true;;
    h) print_usage; exit 0;; H) CASS_HOME=${OPTARG%/};; i) INCREMENTAL=true;; I) ACTION="inventory";;
    j) BZIP=true; COMPRESSION=true; TAR_CFLAG="-j"; TAR_EXT="tbz";; k) KEEP_OLD_FILES=true;;
    l) LOG_OUTPUT=true; [ -d $OPTARG ] && LOG_DIR=${OPTARG%/};; L) INCLUDE_COMMIT_LOGS=true;;
    n) DRY_RUN=true;; N) NICE_LEVEL=$OPTARG;; p) CASSANDRA_PASS=$OPTARG;; r) ACTION="restore";;
    s) SPLIT_SIZE="${OPTARG/[a-z]*[A-Z]*}M"; SPLIT_FILE=true;; S) SERVICE_NAME=$OPTARG;;
    T) COMPRESS_DIR=${OPTARG%/};; u) CASSANDRA_USER=$OPTARG; USE_AUTH=true;; U) USER_FILE=$OPTARG; USE_AUTH=true;;
    v) VERBOSE=true;; w) INCLUDE_CACHES=true;; y) YAML_FILE=$OPTARG;; z) COMPRESSION=true; TAR_CFLAG="-z"; TAR_EXT="tgz";;
    ?) print_help;;
  esac
done

ACTION=${ACTION:-backup}
AUTO_RESTART=true
BACKUP_DIR=${BACKUP_DIR:-/cassandra/backups}
LOG_DIR=${LOG_DIR:-/var/log/cassandra}
SERVICE_NAME=${SERVICE_NAME:-cassandra}
YAML_FILE=${YAML_FILE:-/etc/cassandra/cassandra.yaml}
validate
eval $ACTION
