import os
import subprocess
import time

def send_email(subject, message, recipient):
    command = f'echo "{message}" | mail -s "{subject}" "{recipient}"'
    os.system(command)

#function for notification before cleanup
def notify_before_cleanup():
    subject = "Cassandra Cleanup Starting"
    message = "The Cassandra cleanup process is starting. Please be aware that old data files, snapshots, and commit logs will be deleted."
    recipient = "your-email@example.com"  # Replace with actual recipient email address
    send_email(subject, message, recipient)

def notify_after_cleanup():
    subject = "Cassandra Cleanup Completed"
    message = "The Cassandra cleanup process has been completed successfully. All old data files, snapshots, and commit logs have been deleted (or retained based on your settings)."
    recipient = "your-email@example.com"  # Replace with actual recipient email address
    send_email(subject, message, recipient)

def is_cassandra_running():
    result = subprocess.run(["nodetool", "status"], capture_output=True, text=True)
    return "Connection refused" not in result.stdout

def restore_stop_cassandra():
    if os.getenv("DRY_RUN"):
        print("DRY RUN: Flushing and Stopping Cassandra")
    else:
        if not is_cassandra_running():
            print("Cassandra already stopped")
        else:
            subprocess.run(["nodetool", "flush"])
            subprocess.run(["service", os.getenv("SERVICE_NAME", "cassandra"), "stop"])
            while is_cassandra_running():
                print("Waiting for Cassandra to stop...")
                time.sleep(2)

def restore_start_cassandra():
    if os.getenv("DRY_RUN"):
        print("DRY RUN: Starting Cassandra")
    elif os.getenv("AUTO_RESTART"):
        subprocess.run(["service", os.getenv("SERVICE_NAME", "cassandra"), "start"])

def restore_cleanup():
    if os.getenv("DRY_RUN"):
        print("DRY RUN: Would have deleted old data files")
    else:
        notify_before_cleanup()
        if os.getenv("KEEP_OLD_FILES"):
            print("Keeping old files")
        else:
            print("Deleting old files")
            date = os.getenv("DATE", "$(date +%Y%m%d)")
            directories = [
                f"{os.getenv('COMMITLOG_DIRECTORY')}_old_{date}",
                f"{os.getenv('SAVED_CACHES_DIRECTORY')}_old_{date}",
                f"{os.getenv('BACKUP_DIR')}/restore"
            ]
            for directory in directories:
                subprocess.run(["rm", "-rf", directory])
        notify_after_cleanup()

def snapshot_cleanup():
    if os.getenv("DRY_RUN"):
        print("DRY RUN: Would have deleted old snapshots")
    else:
        print("Deleting old snapshots")
        subprocess.run(["nodetool", "clearsnapshot"])

# Main execution flow
restore_stop_cassandra()
restore_cleanup()
restore_start_cassandra()
