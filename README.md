# Cassandra Cleanup Script

## Overview
This script automates the cleanup process for a Cassandra database, ensuring that old data files, snapshots, and commit logs are efficiently removed while maintaining database integrity.

## Features
- ✅ **Automated Cleanup**: Prevents disk space issues by removing old files and logs.
- ✅ **Safe Shutdown & Restart**: Ensures Cassandra is stopped before cleanup and restarted afterward.
- ✅ **Email Notifications**: Sends alerts before and after the cleanup process.
- ✅ **Optimized File Deletion**: Uses `find` and `parallel/xargs` for efficient bulk deletion.
- ✅ **Dry Run Mode (`$DRY_RUN`)**: Allows testing the script without making actual changes.

## What the Script Does

### 1️⃣ Sends Email Notifications
- Before cleanup starts, an email is sent to notify users.
- After cleanup is completed, another email is sent.

### 2️⃣ Stops Cassandra Before Cleanup
#### `restore_stop_cassandra`
- Safely stops the Cassandra service.
- First, it checks if Cassandra is already stopped.
- If running, it flushes data (`nodetool flush`) and then stops the service.

### 3️⃣ Performs Cleanup
#### `restore_cleanup`
- Deletes old data files, snapshots, and commit logs (unless `$KEEP_OLD_FILES` is set).
- Uses `find` and `parallel/xargs` to efficiently delete directories.

#### `snapshot_cleanup`
- Deletes old snapshots using `nodetool clearsnapshot`

### 4️⃣ Restarts Cassandra After Cleanup
#### `restore_start_cassandra`
- Restarts Cassandra (if `$AUTO_RESTART` is enabled)

---

## Usage
To run the script, ensure Cassandra is installed and configured properly. Modify the script variables as needed, then execute:

## Performance
The casandra_check.py and cassandra_check.java files will be used to perfrom cassandra cleanup operations but the casandra_check.py is efficient file compared to the .java file.

```bash
./cleanup_script.sh
