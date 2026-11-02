#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Box & Terminal UI Drawing Library
# ==============================================================================

# Get terminal dimensions safely
get_term_width() {
    local w
    w=$(tput cols 2>/dev/null)
    if [ -z "$w" ] || [ "$w" -lt 40 ]; then
        echo 80
    else
        echo "$w"
    fi
}

get_term_height() {
    local h
    h=$(tput lines 2>/dev/null)
    if [ -z "$h" ] || [ "$h" -lt 15 ]; then
        echo 24
    else
        echo "$h"
    fi
}

# Draw a horizontal line of specified character and width
draw_line() {
    local char="${1:-─}"
    local width="${2:-$(get_term_width)}"
    local color="${3:-$CLR_MUTED}"
    
    printf "${color}"
    printf '%*s' "$width" '' | tr ' ' "$char"
    printf "${RESET}\n"
}

# Center-align text within given width
center_text() {
    local text="$1"
    local width="${2:-$(get_term_width)}"
    local stripped
    # Strip ANSI codes to calculate actual visual length
    stripped=$(printf "%b" "$text" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local text_len=${#stripped}
    local pad=$(( (width - text_len) / 2 ))
    if [ "$pad" -lt 0 ]; then pad=0; fi
    printf "%*s%b%*s\n" "$pad" "" "$text" "$pad" ""
}

# Draw modern rounded boxed container
draw_box() {
    local title="$1"
    local content="$2"
    local color="${3:-$CLR_PRIMARY}"
    local width="${4:-76}"

    local term_w
    term_w=$(get_term_width)
    if [ "$width" -gt "$term_w" ]; then
        width=$((term_w - 4))
    fi

    # Top border with title
    local title_len=${#title}
    local top_fill=$((width - title_len - 4))
    if [ "$top_fill" -lt 0 ]; then top_fill=0; fi

    printf "${color}╭─┤ ${BOLD}${CLR_TEXT}%s${RESET}${color} ├" "$title"
    printf '%*s' "$top_fill" '' | tr ' ' '─'
    printf "╮${RESET}\n"

    # Print content lines
    while IFS= read -r line; do
        local stripped
        stripped=$(printf "%b" "$line" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        local line_len=${#stripped}
        local pad=$((width - line_len - 2))
        if [ "$pad" -lt 0 ]; then pad=0; fi
        printf "${color}│${RESET} %b%*s ${color}│${RESET}\n" "$line" "$pad" ""
    done <<< "$content"

    # Bottom border
    printf "${color}╰"
    printf '%*s' "$((width))" '' | tr ' ' '─'
    printf "╯${RESET}\n"
}

# Display an alert badge / notification box
draw_alert() {
    local type="$1"     # SUCCESS, DANGER, WARNING, INFO
    local message="$2"
    local width="${3:-76}"

    local color="$CLR_INFO"
    local icon="[i]"
    case "$type" in
        SUCCESS) color="$CLR_SUCCESS"; icon="[✓]" ;;
        DANGER)  color="$CLR_DANGER";  icon="[!]" ;;
        WARNING) color="$CLR_WARNING"; icon="[▲]" ;;
        INFO)    color="$CLR_INFO";    icon="[ℹ]" ;;
    esac

    printf "\n${color}┌─ %s %s " "$icon" "$type"
    local fill=$((width - ${#type} - 9))
    if [ "$fill" -lt 0 ]; then fill=0; fi
    printf '%*s' "$fill" '' | tr ' ' '─'
    printf "┐${RESET}\n"
    
    printf "${color}│${RESET}  %b\n" "$message"
    
    printf "${color}└"
    printf '%*s' "$width" '' | tr ' ' '─'
    printf "┘${RESET}\n\n"
}
