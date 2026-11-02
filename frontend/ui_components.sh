#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Frontend UI Components
# Powered by Linux Commands: tput, printf, sed, tr, date, cut
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source dependencies
# shellcheck source=dependencies/colors.sh
[ -f "$ROOT_DIR/dependencies/colors.sh" ] && . "$ROOT_DIR/dependencies/colors.sh"
# shellcheck source=dependencies/boxes.sh
[ -f "$ROOT_DIR/dependencies/boxes.sh" ] && . "$ROOT_DIR/dependencies/boxes.sh"
# shellcheck source=dependencies/icons.sh
[ -f "$ROOT_DIR/dependencies/icons.sh" ] && . "$ROOT_DIR/dependencies/icons.sh"
# shellcheck source=backend/auth.sh
[ -f "$ROOT_DIR/backend/auth.sh" ] && . "$ROOT_DIR/backend/auth.sh"
# shellcheck source=backend/students.sh
[ -f "$ROOT_DIR/backend/students.sh" ] && . "$ROOT_DIR/backend/students.sh"

# Clear terminal screen cleanly
clear_screen() {
    clear 2>/dev/null || tput clear 2>/dev/null || printf "\033c"
}

# Render Application Brand Header Banner
render_header() {
    local term_w
    term_w=$(get_term_width)

    printf "\n"
    printf "${CLR_PRIMARY}${BOLD}"
    center_text "╔════════════════════════════════════════════════════════════════════════════╗" "$term_w"
    center_text "║          🎓  APEX UNIVERSITY — STUDENT RECORD MANAGEMENT SYSTEM          ║" "$term_w"
    center_text "║              Enterprise Academic Administration & Student Portal           ║" "$term_w"
    center_text "╚════════════════════════════════════════════════════════════════════════════╝" "$term_w"
    printf "${RESET}\n"
}

# Render Status & Context Bar
render_status_bar() {
    local term_w
    term_w=$(get_term_width)

    local cur_user cur_role student_count cur_time
    cur_user=$(get_current_name)
    cur_user="${cur_user:-Guest Visitor}"
    cur_role=$(get_current_role)
    student_count=$(get_student_count)
    cur_time=$(date "+%a, %b %d %Y • %I:%M %p")

    local role_badge
    case "$cur_role" in
        admin)   role_badge="${CLR_DANGER}${BOLD}[ADMIN]${RESET}" ;;
        faculty) role_badge="${CLR_WARNING}${BOLD}[FACULTY]${RESET}" ;;
        *)       role_badge="${CLR_INFO}${BOLD}[GUEST]${RESET}" ;;
    esac

    printf "${BG_CARD}${CLR_TEXT} %s %b ${CLR_MUTED}•${RESET}${BG_CARD} %s %s ${CLR_MUTED}•${RESET}${BG_CARD} %s %s Enrolled ${CLR_MUTED}•${RESET}${BG_CARD} %s ${RESET}\n" \
        "$ICON_STUDENT" "$role_badge" "$cur_user" "$ICON_APP" "$student_count" "$ICON_ATTENDANCE" "$cur_time"
    draw_line "─" "$term_w" "$CLR_MUTED"
}

# Pause prompt
pause_key() {
    local prompt="${1:-Press [Enter] to continue...}"
    printf "\n${CLR_MUTED}%s${RESET}" "$prompt"
    read -r _
}

# Prompt user for input with styling, default value, and optional validator
# Usage: prompt_input "Enter Full Name" "var_name" "Default Val" "validator_fn"
prompt_input() {
    local label="$1"
    local var_name="$2"
    local default_val="$3"
    local validator="$4"

    local input=""
    while true; do
        if [ -n "$default_val" ]; then
            printf "${CLR_PRIMARY}▶ ${CLR_TEXT}%s ${CLR_MUTED}[%s]${CLR_TEXT}: ${RESET}" "$label" "$default_val"
        else
            printf "${CLR_PRIMARY}▶ ${CLR_TEXT}%s: ${RESET}" "$label"
        fi

        read -r input
        if [ -z "$input" ] && [ -n "$default_val" ]; then
            input="$default_val"
        fi

        # If validator function provided, check it
        if [ -n "$validator" ] && [ -n "$input" ]; then
            if ! "$validator" "$input"; then
                printf "${CLR_DANGER}  [!] Invalid input format. Please try again.${RESET}\n"
                continue
            fi
        fi

        if [ -n "$input" ] || [ -n "$default_val" ]; then
            eval "$var_name=\"\$input\""
            break
        else
            printf "${CLR_DANGER}  [!] This field cannot be empty.${RESET}\n"
        fi
    done
}

# Animated Spinner for aesthetic feedback
show_spinner() {
    local pid="$1"
    local message="${2:-Processing...}"
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    # Hide cursor
    tput civis 2>/dev/null

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % ${#spin_chars} ))
        local char="${spin_chars:$i:1}"
        printf "\r${CLR_ACCENT}%s ${CLR_TEXT}%s...${RESET}" "$char" "$message"
        sleep 0.08
    done

    # Show cursor
    tput cnorm 2>/dev/null
    printf "\r%*s\r" $(( ${#message} + 20 )) ""
}

# Render a formatted table
# Args:
#   $1: column widths (space-separated, e.g., "12 24 22 6 12")
#   $2: column headers (pipe-separated, e.g., "Roll No|Full Name|Department|Sem|Status")
#   $3: data stream (stdin or variable, pipe-separated records)
render_table() {
    local widths_str="$1"
    local headers_str="$2"
    local data="$3"

    read -r -a widths <<< "$widths_str"
    IFS='|' read -r -a headers <<< "$headers_str"
    local col_count=${#headers[@]}

    # Top border
    printf "${CLR_PRIMARY}╭"
    for ((i=0; i<col_count; i++)); do
        local w=${widths[i]}
        printf '%*s' "$((w + 2))" '' | tr ' ' '─'
        if [ $i -lt $((col_count - 1)) ]; then
            printf "┬"
        else
            printf "╮${RESET}\n"
        fi
    done

    # Header Row
    printf "${CLR_PRIMARY}│${RESET}"
    for ((i=0; i<col_count; i++)); do
        local w=${widths[i]}
        local h="${headers[i]}"
        printf " ${BOLD}${CLR_ACCENT}%-*s${RESET} ${CLR_PRIMARY}│${RESET}" "$w" "$h"
    done
    printf "\n"

    # Middle Header Divider
    printf "${CLR_PRIMARY}├"
    for ((i=0; i<col_count; i++)); do
        local w=${widths[i]}
        printf '%*s' "$((w + 2))" '' | tr ' ' '─'
        if [ $i -lt $((col_count - 1)) ]; then
            printf "┼"
        else
            printf "┤${RESET}\n"
        fi
    done

    # Rows
    local row_idx=0
    while IFS= read -r row; do
        [ -z "$row" ] && continue
        row_idx=$((row_idx + 1))
        IFS='|' read -r -a cells <<< "$row"

        local row_color=""
        if [ $((row_idx % 2)) -eq 0 ]; then
            row_color="${CLR_TEXT}"
        else
            row_color="${CLR_INFO}"
        fi

        printf "${CLR_PRIMARY}│${RESET}"
        for ((i=0; i<col_count; i++)); do
            local w=${widths[i]}
            local c="${cells[i]}"
            printf " %b%-*s${RESET} ${CLR_PRIMARY}│${RESET}" "$row_color" "$w" "$c"
        done
        printf "\n"
    done <<< "$data"

    # Bottom border
    printf "${CLR_PRIMARY}╰"
    for ((i=0; i<col_count; i++)); do
        local w=${widths[i]}
        printf '%*s' "$((w + 2))" '' | tr ' ' '─'
        if [ $i -lt $((col_count - 1)) ]; then
            printf "┴"
        else
            printf "╯${RESET}\n"
        fi
    done
}
