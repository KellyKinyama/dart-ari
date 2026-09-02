#!/bin/sh

# Set the working directory
cd /usr/src/ari_proxy

# --- Configuration ---
LOG_FILE="enricher.log"
LOGS_DIR="logs"

# --- Log Backup Logic ---

# Create the logs subdirectory if it doesn't already exist.
mkdir -p "$LOGS_DIR"

# Check if the log file exists from a previous run
if [ -f "$LOG_FILE" ]; then
    # Create a timestamp e.g., 2025-09-11_11-14-15
    TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')

    # Move the existing log file into the logs subfolder with the timestamp
    mv "$LOG_FILE" "${LOGS_DIR}/enricher_${TIMESTAMP}.log"
    echo "Backed up existing log to ${LOGS_DIR}/enricher_${TIMESTAMP}.log"
fi

# --- Application Execution ---

# Log the start time
echo "$(date +'%Y-%m-%d_%H-%M-%S'): Starting application..." > "$LOG_FILE"

# Start the application.
# ">>" appends the log to the file.
# "2>&1" redirects Standard Error (stderr, file descriptor 2) to the same place as
# Standard Output (stdout, file descriptor 1), capturing crash/error messages.
./enrich_from_homer.exe >> "$LOG_FILE" 2>&1

# --- Crash/Exit Status Check ---

# Capture the exit status ($?) of the application
EXIT_STATUS=$?

# Log the exit status
if [ "$EXIT_STATUS" -ne 0 ]; then
    echo "$(date +'%Y-%m-%d_%H-%M-%S'): Application **CRASHED** or exited with status: $EXIT_STATUS" >> "$LOG_FILE"
else
    echo "$(date +'%Y-%m-%d_%H-%M-%S'): Application exited successfully with status: $EXIT_STATUS" >> "$LOG_FILE"
fi

# End of script
