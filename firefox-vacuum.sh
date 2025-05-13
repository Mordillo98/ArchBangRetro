#!/bin/bash

# ~/.config/openbox/firefox-preload.sh
# Preloads Firefox files into RAM cache using vmtouch.
# Further optimizes startup by running a quick headless command after vmtouch.
# Logs output to ~/.cache/firefox-preload/firefox-preload.log

# --- Log Configuration ---
LOG_DIR="$HOME/.cache/firefox-preload"
LOG_FILE="$LOG_DIR/firefox-preload.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR" || {
    echo "FATAL: Cannot create log directory $LOG_DIR. Exiting." >&2
    exit 1
}

# Redirect stdout and stderr to the log file (append mode)
exec >> "$LOG_FILE" 2>&1

# --- Script Start Log ---
echo "============================================================"
echo "Firefox Preload Script Started (v6 - real profile with complete session cleanup): $(date)"
echo "Logging to: $LOG_FILE"

# --- Configuration ---

# Locate Firefox installation directory (usually /usr/lib/firefox)
FIREFOX_LIB_DIR="/usr/lib/firefox"
# Find firefox executable
FIREFOX_BIN=$(command -v firefox)

# Attempt to locate the default Firefox profile directory
PROFILE_DIR=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name '*.default-release' -print -quit)
if [ -z "$PROFILE_DIR" ]; then
    PROFILE_DIR=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name '*.default' -print -quit)
fi
if [ -z "$PROFILE_DIR" ]; then
    echo "INFO: Default profile patterns ('*.default-release', '*.default') not found, attempting broader search..."
    PROFILE_DIR=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name '*.' ! -name '.' ! -name '..' ! -name '*Crash Reports*' ! -name '*Pending Pings*' -print -quit)
fi

# --- Sanity Checks ---

if ! command -v vmtouch &> /dev/null; then
    echo "ERROR: vmtouch command not found. Please install it ('sudo pacman -S vmtouch'). Exiting preload script."
    exit 1
fi

if [ -z "$FIREFOX_BIN" ]; then
    echo "ERROR: firefox executable not found in PATH. Cannot perform headless ping."
fi

# --- Build Target List ---
TARGETS=()

if [ -d "$FIREFOX_LIB_DIR" ]; then
    echo "INFO: Adding library directory: $FIREFOX_LIB_DIR"
    TARGETS+=("$FIREFOX_LIB_DIR")
else
    echo "WARNING: Library directory not found: $FIREFOX_LIB_DIR. vmtouch may be less effective."
fi

if [ -d "$PROFILE_DIR" ]; then
    echo "INFO: Adding profile directory: $PROFILE_DIR"
    TARGETS+=("$PROFILE_DIR")
else
    echo "WARNING: Profile directory not found under ~/.mozilla/firefox/. vmtouch may be less effective."
fi

# --- Execute Preloading and Headless Ping Sequentially in Background ---

PRELOAD_BG_PID=""
if [ ${#TARGETS[@]} -gt 0 ]; then
    echo "INFO: Starting background task for vmtouch and subsequent headless ping..."
    (
        echo "INFO: Background task (PID $$) starting vmtouch preload at $(date) for targets: ${TARGETS[*]}"
        nice ionice -c 3 vmtouch -f -v -t "${TARGETS[@]}"
        VTOUCH_EXIT_CODE=$?
        echo "INFO: Background task (PID $$) finished vmtouch at $(date) with exit code $VTOUCH_EXIT_CODE"

        # Use the real profile for headless execution, then remove all session-related files.
        if [ "$VTOUCH_EXIT_CODE" -eq 0 ] && [ -n "$FIREFOX_BIN" ]; then
            echo "INFO: Background task (PID $$) attempting quick headless Firefox execution with real profile..."
            SCREENSHOT_FILE="$LOG_DIR/preload_screenshot.png"
            nice ionice -c 3 "$FIREFOX_BIN" --headless --screenshot "$SCREENSHOT_FILE" >/dev/null 2>&1
            HEADLESS_EXIT_CODE=$?
            rm -f "$SCREENSHOT_FILE"

            # Wait briefly to ensure Firefox writes any session files
            sleep 1

            # Remove sessionstore, recovery, and upgrade files from the profile
            for FILE in "$PROFILE_DIR"/sessionstore*.jsonlz4 "$PROFILE_DIR"/recovery*.jsonlz4 "$PROFILE_DIR"/upgrade*.jsonlz4; do
                if [ -e "$FILE" ]; then
                    echo "INFO: Removing $FILE to avoid session restore prompt."
                    rm -f "$FILE"
                fi
            done

            # Also remove the sessionstore-backups directory if it exists
            if [ -d "$PROFILE_DIR/sessionstore-backups" ]; then
                echo "INFO: Removing sessionstore-backups directory to avoid session restore prompt."
                rm -rf "$PROFILE_DIR/sessionstore-backups"
            fi

            echo "INFO: Background task (PID $$) finished headless Firefox ping at $(date) with exit code $HEADLESS_EXIT_CODE"
        elif [ -z "$FIREFOX_BIN" ]; then
            echo "INFO: Skipping headless ping because Firefox binary was not found."
        else
            echo "INFO: Skipping headless ping because vmtouch exited with code $VTOUCH_EXIT_CODE."
        fi
        echo "INFO: Background task (PID $$) completed."
    ) &
    PRELOAD_BG_PID=$!
    echo "INFO: Preload & Ping task launched in background (PID: $PRELOAD_BG_PID). Preloading asynchronously."
else
    echo "WARNING: No valid Firefox directories found for preloading."
fi

# --- Script Finish Log ---
echo "Firefox Preload Script finished initiating background task: $(date)"
echo "Background PID: $PRELOAD_BG_PID"
echo "============================================================"

exit 0
