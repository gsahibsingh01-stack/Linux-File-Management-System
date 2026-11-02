#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Visual Analytics & Statistics UI
# Powered by Linux Commands: awk, sort, cut, printf
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=frontend/ui_components.sh
[ -f "$SCRIPT_DIR/ui_components.sh" ] && . "$SCRIPT_DIR/ui_components.sh"
# shellcheck source=backend/analytics.sh
[ -f "$ROOT_DIR/backend/analytics.sh" ] && . "$ROOT_DIR/backend/analytics.sh"

ui_view_analytics() {
    clear_screen
    render_header
    render_status_bar

    c_println "$CLR_PRIMARY" "${BOLD}  ACADEMIC PERFORMANCE & ENROLLMENT ANALYTICS${RESET}"
    c_println "$CLR_MUTED" "  Real-time KPI metrics, department distribution charts, and honors leaderboard.\n"

    # 1. Dean's Honor Roll (Top Performers)
    echo "  ╔══════════════════════════════════════════════════════════════════════════╗"
    echo "  ║          🏆  DEAN'S HONOR ROLL — TOP ACADEMIC PERFORMERS (CGPA)          ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════════╝"

    local top_data
    top_data=$(get_top_students 5)

    if [ -n "$top_data" ]; then
        local table_data
        table_data=$(echo "$top_data" | awk -F'|' '
            {
                medal = ($1 == 1) ? "🥇 Rank 1" : (($1 == 2) ? "🥈 Rank 2" : (($1 == 3) ? "🥉 Rank 3" : ("   Rank " $1)));
                printf "%-9s|%-11s|%-22s|%-22s|%-10s\n",
                    medal, $2, substr($3, 1, 22), substr($4, 1, 22), $5 " / 10.0"
            }
        ')
        render_table "9 11 22 22 10" "Standing|Roll Number|Student Name|Department|CGPA Score" "$table_data"
    else
        echo "  No evaluated course marks available yet."
    fi

    printf "\n"

    # 2. Department-wise Enrollment Visual Bar Chart
    echo "  ╔══════════════════════════════════════════════════════════════════════════╗"
    echo "  ║       📊  DEPARTMENTAL ENROLLMENT DISTRIBUTION (ASCII BAR CHART)         ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════════╝"

    local dept_data
    dept_data=$(get_department_distribution)

    if [ -n "$dept_data" ]; then
        echo "$dept_data" | while IFS='|' read -r dept count pct; do
            # Compute bar length out of 25 blocks
            local bar_len
            bar_len=$(awk -v p="$pct" 'BEGIN { printf "%d", (p / 100) * 25 }')
            if [ "$bar_len" -lt 1 ] && [ "$count" -gt 0 ]; then bar_len=1; fi

            local bar=""
            for ((b=0; b<bar_len; b++)); do bar="${bar}█"; done
            for ((s=bar_len; s<25; s++)); do bar="${bar}░"; done

            printf "  %-24s ${CLR_ACCENT}[%s]${RESET} ${BOLD}%5.1f%%${RESET} (${count} students)\n" \
                "$dept" "$bar" "$pct"
        done
    fi

    printf "\n"

    # 3. Gender Demographics Breakdown
    echo "  ╔══════════════════════════════════════════════════════════════════════════╗"
    echo "  ║                    👥  STUDENT GENDER DEMOGRAPHICS                      ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════════╝"

    local gender_data
    gender_data=$(get_gender_distribution)
    if [ -n "$gender_data" ]; then
        echo "$gender_data" | while IFS='|' read -r gen count pct; do
            local bar_len
            bar_len=$(awk -v p="$pct" 'BEGIN { printf "%d", (p / 100) * 20 }')
            local bar=""
            for ((b=0; b<bar_len; b++)); do bar="${bar}█"; done
            for ((s=bar_len; s<20; s++)); do bar="${bar}░"; done

            printf "  %-10s ${CLR_PRIMARY}[%s]${RESET} ${BOLD}%5.1f%%${RESET} (%d students)\n" \
                "$gen" "$bar" "$pct" "$count"
        done
    fi

    pause_key
}
