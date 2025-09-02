#!/bin/bash
# ~/.config/openbox/firefox-preload.sh
# Preload Firefox code/data via vmtouch, then do a SAFE headless warm-up
# with a throwaway profile (avoids locks/crashes). Logs to ~/.cache/firefox-preload/firefox-preload.log
# Arch Linux / bash / ADD-friendly: simple, fast, no surprises.

set -o nounset
set -o pipefail

# ----------------------- Colors (per your prefs) -----------------------
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# ----------------------- Log Configuration ----------------------------
LOG_DIR="$HOME/.cache/firefox-preload"
LOG_FILE="$LOG_DIR/firefox-preload.log"

mkdir -p "$LOG_DIR" || {
    printf "${RED}FATAL:${NC} Cannot create log directory %s. Exiting.\n" "$LOG_DIR" >&2
    exit 1
}

# Redirect stdout/stderr to log (append)
exec >> "$LOG_FILE" 2>&1

printf "============================================================\n"
printf "Firefox Preload Script Started (v7 - safe throwaway profile): %s\n" "$(date)"
printf "Logging to: %s\n" "$LOG_FILE"

# ----------------------- Configuration -------------------------------
FIREFOX_LIB_DIR="/usr/lib/firefox"
FIREFOX_BIN="$(command -v firefox || true)"

# Resolve a likely default profile dir (used ONLY for vmtouch warming)
PROFILE_DIR="$(find "$HOME/.mozilla/firefox/" -maxdepth 1 -type d -name '*.default-release' -print -quit 2>/dev/null || true)"
if [ -z "${PROFILE_DIR:-}" ]; then
    PROFILE_DIR="$(find "$HOME/.mozilla/firefox/" -maxdepth 1 -type d -name '*.default' -print -quit 2>/dev/null || true)"
fi
if [ -z "${PROFILE_DIR:-}" ]; then
    printf "${YELLOW}INFO:${NC} Default profile not found by pattern; skipping profile vmtouch unless found later.\n"
fi

# ----------------------- Sanity Checks -------------------------------
if ! command -v vmtouch >/dev/null 2>&1; then
    printf "${RED}ERROR:${NC} vmtouch not found. Install it: sudo pacman -S vmtouch\n"
    exit 1
fi

if [ -z "${FIREFOX_BIN}" ]; then
    printf "${YELLOW}WARN:${NC} firefox binary not found in PATH. Headless warm-up will be skipped.\n"
fi

# ----------------------- Build Target List ---------------------------
TARGETS=()

if [ -d "$FIREFOX_LIB_DIR" ]; then
    printf "${CYAN}INFO:${NC} Adding library directory: %s\n" "$FIREFOX_LIB_DIR"
    TARGETS+=("$FIREFOX_LIB_DIR")
else
    printf "${YELLOW}WARN:${NC} Library directory not found: %s (vmtouch less effective).\n" "$FIREFOX_LIB_DIR"
fi

if [ -n "${PROFILE_DIR:-}" ] && [ -d "$PROFILE_DIR" ]; then
    printf "${CYAN}INFO:${NC} Adding profile directory (for cache warm): %s\n" "$PROFILE_DIR"
    TARGETS+=("$PROFILE_DIR")
else
    printf "${YELLOW}INFO:${NC} No profile directory added for vmtouch.\n"
fi

# ----------------------- Execute in Background -----------------------
PRELOAD_BG_PID=""
if [ "${#TARGETS[@]}" -gt 0 ]; then
    printf "${CYAN}INFO:${NC} Starting background vmtouch + safe headless warm-up...\n"
    (
        printf "${CYAN}INFO:${NC} Background task (PID %d) vmtouch preload start: %s\n" "$$" "$(date)"
        nice ionice -c 3 vmtouch -f -v -t "${TARGETS[@]}"
        VMTOUCH_EXIT_CODE=$?
        printf "${CYAN}INFO:${NC} Background task (PID %d) vmtouch finished: %s (exit %d)\n" "$$" "$(date)" "$VMTOUCH_EXIT_CODE"

        # ---------------- SAFE Headless Warm-up ----------------
        # Avoid touching the real profile. Use a throwaway one with --no-remote and a hard timeout.
        if [ "$VMTOUCH_EXIT_CODE" -eq 0 ] && [ -n "${FIREFOX_BIN}" ]; then
            printf "${CYAN}INFO:${NC} Using throwaway profile for headless warm-up to avoid locks/crashes.\n"
            TMP_PROFILE="$(mktemp -d -t ff-preload-XXXXXXXX)"
            SCREENSHOT_FILE="$LOG_DIR/preload_screenshot.png"
            TIMEOUT_SECS=15

            printf "${CYAN}INFO:${NC} Launching headless Firefox --no-remote (timeout: %ss)\n" "$TIMEOUT_SECS"
            timeout "${TIMEOUT_SECS}s" nice ionice -c 3 \
                "$FIREFOX_BIN" --headless --no-remote \
                --profile "$TMP_PROFILE" \
                --screenshot "$SCREENSHOT_FILE" about:blank >/dev/null 2>&1
            HEADLESS_EXIT_CODE=$?

            rm -f "$SCREENSHOT_FILE"

            # Treat timeout (124) as acceptable for warming purposes.
            if [ "$HEADLESS_EXIT_CODE" -eq 0 ] || [ "$HEADLESS_EXIT_CODE" -eq 124 ]; then
                printf "${GREEN}INFO:${NC} Headless warm-up completed (exit %d). No crash expected.\n" "$HEADLESS_EXIT_CODE"
            else
                printf "${YELLOW}WARN:${NC} Headless warm-up returned nonzero exit %d. Proceeding anyway.\n" "$HEADLESS_EXIT_CODE"
            fi

            rm -rf "$TMP_PROFILE"
            printf "${CYAN}INFO:${NC} Throwaway profile removed.\n"
        else
            if [ -z "${FIREFOX_BIN}" ]; then
                printf "${YELLOW}INFO:${NC} Skipping headless warm-up: firefox binary not found.\n"
            else
                printf "${YELLOW}INFO:${NC} Skipping headless warm-up: vmtouch exit %d.\n" "$VMTOUCH_EXIT_CODE"
            fi
        fi

        printf "${CYAN}INFO:${NC} Background task (PID %d) completed.\n" "$$"
    ) &
    PRELOAD_BG_PID=$!
    printf "${CYAN}INFO:${NC} Preload & Warm-up launched in background (PID: %s).\n" "$PRELOAD_BG_PID"
else
    printf "${YELLOW}WARN:${NC} No valid directories found for vmtouch warming.\n"
fi

# ----------------------- Finish --------------------------------------
printf "Firefox Preload Script finished initiating background task: %s\n" "$(date)"
printf "Background PID: %s\n" "${PRELOAD_BG_PID:-}"
printf "============================================================\n"

exit 0
