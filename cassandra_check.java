//importing required moduels
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

public class CassandraCleanup {

    private static void sendEmail(String subject, String message, String recipient) {
        String command = String.format("echo \"%s\" | mail -s \"%s\" \"%s\"", message, subject, recipient);
        runCommand(command);
    }

    private static void notifyBeforeCleanup() {
        String subject = "Cassandra Cleanup i getting Started";
        String message = "The Cassandra cleanup process is starting. Please be aware that old data files, snapshots, and commit logs will be deleted.";
        String recipient = "your-email@example.com"; // Replace with actual recipient
        sendEmail(subject, message, recipient);
    }

    private static void notifyAfterCleanup() {
        String subject = "Cassandra Cleanup task has been Completed";
        String message = "The Cassandra cleanup process has been completed successfully. All old data files, snapshots, and commit logs have been deleted (or retained based on your settings).";
        String recipient = "your-email@example.com"; // Replace with actual recipient
        sendEmail(subject, message, recipient);
    }

    private static boolean isCassandraRunning() {
        String result = runCommandWithOutput("nodetool status");
        return !result.contains("Connection refused");
    }

    private static void restoreStopCassandra() {
        if (System.getenv("DRY_RUN") != null) {
            System.out.println("DRY RUN: Flushing and Stopping Cassandra Database");
            return;
        }

        if (!isCassandraRunning()) {
            System.out.println("Cassandra database has already stopped");
            return;
        }

        runCommand("nodetool flush");
        runCommand("service " + getEnvOrDefault("SERVICE_NAME", "cassandra") + " stop");

        while (isCassandraRunning()) {
            System.out.println("Waiting for Cassandra database to stop...");
            sleep(2000);
        }
    }

    private static void restoreStartCassandra() {
        if (System.getenv("DRY_RUN") != null) {
            System.out.println("DRY RUN: Starting Cassandra");
        } else if (System.getenv("AUTO_RESTART") != null) {
            runCommand("service " + getEnvOrDefault("SERVICE_NAME", "cassandra") + " start");
        }
    }

    private static void restoreCleanup() {
        if (System.getenv("DRY_RUN") != null) {
            System.out.println("DRY RUN: Would have deleted old data files");
            return;
        }

        notifyBeforeCleanup();

        if (System.getenv("KEEP_OLD_FILES") != null) {
            System.out.println("Keeping old files");
        } else {
            System.out.println("Deleting old files");
            String date = System.getenv("DATE") != null ? System.getenv("DATE") : new java.text.SimpleDateFormat("yyyyMMdd").format(new java.util.Date());
            List<String> directories = Arrays.asList(
                    System.getenv("COMMITLOG_DIRECTORY") + "_old_" + date,
                    System.getenv("SAVED_CACHES_DIRECTORY") + "_old_" + date,
                    System.getenv("BACKUP_DIR") + "/restore"
            );

            for (String dir : directories) {
                runCommand("rm -rf " + dir);
            }
        }

        notifyAfterCleanup();
    }

    private static void snapshotCleanup() {
        if (System.getenv("DRY_RUN") != null) {
            System.out.println("DRY RUN: Would have deleted old snapshots");
        } else {
            System.out.println("Deleting old snapshots");
            runCommand("nodetool clearsnapshot");
        }
    }

    private static void runCommand(String command) {
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"/bin/sh", "-c", command});
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }

    private static String runCommandWithOutput(String command) {
        StringBuilder output = new StringBuilder();
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"/bin/sh", "-c", command});
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
        return output.toString();
    }

    private static String getEnvOrDefault(String key, String defaultValue) {
        String value = System.getenv(key);
        return value != null ? value : defaultValue;
    }

    private static void sleep(int milliseconds) {
        try {
            Thread.sleep(milliseconds);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        restoreStopCassandra();
        restoreCleanup();
        restoreStartCassandra();
    }
}
