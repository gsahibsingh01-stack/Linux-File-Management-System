#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Terminal Color & Style Library
# ==============================================================================

# Check if stdout is a terminal or supports color
if [ -t 1 ]; then
    COLOR_SUPPORT=1
else
    COLOR_SUPPORT=0
fi

# Reset
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
UNDERLINE="\033[4m"
BLINK="\033[5m"
INVERT="\033[7m"

# Standard Foreground Colors
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# High-Intensity Bright Foregrounds
BRIGHT_BLACK="\033[90m"
BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[92m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"
BRIGHT_WHITE="\033[97m"

# Modern 256-Color / FinTech Palette
CLR_PRIMARY="\033[38;5;39m"       # Vivid Sky Blue
CLR_PRIMARY_DARK="\033[38;5;27m"  # Deep Royal Blue
CLR_ACCENT="\033[38;5;45m"        # Electric Cyan
CLR_SUCCESS="\033[38;5;48m"       # Emerald Mint Green
CLR_WARNING="\033[38;5;214m"      # Amber Orange
CLR_DANGER="\033[38;5;196m"       # Coral Crimson Red
CLR_INFO="\033[38;5;117m"         # Soft Sky
CLR_MUTED="\033[38;5;244m"        # Slate Gray
CLR_TEXT="\033[38;5;255m"         # Crisp White
CLR_GOLD="\033[38;5;220m"         # Gold

# Background Colors
BG_DARK="\033[48;5;234m"
BG_CARD="\033[48;5;236m"
BG_PRIMARY="\033[48;5;25m"
BG_SUCCESS="\033[48;5;28m"
BG_WARNING="\033[48;5;130m"
BG_DANGER="\033[48;5;88m"
BG_CYAN="\033[48;5;30m"

# Helper print functions
c_print() {
    local color="$1"
    shift
    printf "${color}%s${RESET}" "$*"
}

c_println() {
    local color="$1"
    shift
    printf "${color}%s${RESET}\n" "$*"
}
