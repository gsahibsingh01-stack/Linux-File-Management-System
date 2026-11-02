#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Attendance UI & Shortage Alert
# Powered by Linux Commands: awk, grep, printf, cut
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=frontend/ui_components.sh
[ -f "$SCRIPT_DIR/ui_components.sh" ] && . "$SCRIPT_DIR/ui_components.sh"
# shellcheck source=backend/students.sh
[ -f "$ROOT_DIR/backend/students.sh" ] && . "$ROOT_DIR/backend/students.sh"
# shellcheck source=backend/attendance.sh
[ -f "$ROOT_DIR/backend/attendance.sh" ] && . "$ROOT_DIR/backend/attendance.sh"

# View Complete Attendance Ledger
ui_view_attendance() {
    clear_screen
    render_header
    render_status_bar

    c_println "$CLR_PRIMARY" "${BOLD}  STUDENT ATTENDANCE & BIOMETRIC REGISTRY${RESET}"
    c_println "$CLR_MUTED" "  Academic attendance percentages, class counts, and compliance status.\n"

    local summary avg_pct shortage_count
    summary=$(get_attendance_summary)
    avg_pct=$(echo "$summary" | cut -d'|' -f1)
    shortage_count=$(echo "$summary" | cut -d'|' -f2)

    printf "  ${CLR_ACCENT}University Average Attendance:${RESET} ${BOLD}%s%%${RESET}  ${CLR_MUTED}•${RESET}  " "$avg_pct"
    if [ "$shortage_count" -gt 0 ]; then
        printf "${CLR_DANGER}${BOLD}%d Student(s) with Attendance Shortage (<75%%)${RESET}\n\n" "$shortage_count"
    else
        printf "${CLR_SUCCESS}All students comply with 75%% minimum threshold${RESET}\n\n"
    fi

    if [ ! -f "$DATA_DIR/attendance.csv" ]; then
        draw_alert "INFO" "No attendance data found."
        pause_key
        return
    fi

    # Join with students.csv for names & departments
    local table_data
    table_data=$(awk -F',' '
        NR == FNR {
            if (FNR > 1) {
                name[$1] = $2;
                dept[$1] = $8;
                sem[$1] = $9;
            }
            next;
        }
        FNR > 1 {
            roll = $1;
            n = (roll in name) ? substr(name[roll], 1, 18) : "Unknown";
            d = (roll in dept) ? substr(dept[roll], 1, 18) : "-";
            tot = $2;
            att = $3;
            pct = $4 + 0.0;
            status_text = (pct >= 75.0) ? "NORMAL" : "SHORTAGE";
            printf "%-11s|%-18s|%-18s|%-7s|%-8s|%-8.1f%%|%-9s\n",
                roll, n, d, tot, att, pct, status_text
        }
    ' "$DATA_DIR/students.csv" "$DATA_DIR/attendance.csv")

    render_table "11 18 18 7 8 8 9" "Roll Number|Student Name|Department|Total|Attended|Percent|Status" "$table_data"

    pause_key
}

# Update Attendance Record for a Student
ui_update_attendance() {
    clear_screen
    render_header
    render_status_bar

    if ! is_faculty; then
        draw_alert "DANGER" "Access Denied: Only Faculty and Administrators can log attendance."
        pause_key
        return
    fi

    c_println "$CLR_PRIMARY" "${BOLD}  RECORD ATTENDANCE SESSIONS${RESET}"
    c_println "$CLR_MUTED" "  Update total conducted hours and attended hours for a student.\n"

    local roll
    prompt_input "Enter Student Roll Number" "roll" "" "validate_roll_no"

    local student_row
    student_row=$(get_student_by_roll "$roll")
    if [ -z "$student_row" ]; then
        draw_alert "DANGER" "Student '$roll' does not exist."
        pause_key
        return
    fi

    local student_name
    student_name=$(echo "$student_row" | cut -d',' -f2)

    local cur_rec cur_total cur_attended cur_pct
    cur_rec=$(get_attendance_record "$roll")
    cur_total=$(echo "$cur_rec" | cut -d',' -f2)
    cur_attended=$(echo "$cur_rec" | cut -d',' -f3)
    cur_pct=$(echo "$cur_rec" | cut -d',' -f4)

    printf "  Student: ${BOLD}%s${RESET} ($roll)\n" "$student_name"
    printf "  Current Attendance: %s / %s classes (${cur_pct}%%)\n\n" "${cur_attended:-0}" "${cur_total:-0}"

    local total attended
    prompt_input "Total Delivered Classes" "total" "${cur_total:-100}" ""
    prompt_input "Attended Classes" "attended" "${cur_attended:-85}" ""

    if update_attendance "$roll" "$total" "$attended"; then
        local new_rec new_pct
        new_rec=$(get_attendance_record "$roll")
        new_pct=$(echo "$new_rec" | cut -d',' -f4)

        draw_alert "SUCCESS" "Attendance updated! New Rate: ${new_pct}% (${attended}/${total} sessions)"
    else
        draw_alert "DANGER" "Failed to update attendance."
    fi

    pause_key
}

# Attendance Shortage Warning Board (<75% debarment warning)
ui_shortage_board() {
    clear_screen
    render_header
    render_status_bar

    c_println "$CLR_DANGER" "${BOLD}  ATTENDANCE SHORTAGE DEFICIENCY & DEBARMENT BOARD (<75%)${RESET}"
    c_println "$CLR_MUTED" "  Mandatory minimum 75% attendance threshold per University Regulations.\n"

    local shortage_data
    shortage_data=$(get_attendance_shortage 75.0)

    if [ -z "$shortage_data" ]; then
        draw_alert "SUCCESS" "Excellent! No students currently fall below the 75% attendance criterion."
        pause_key
        return
    fi

    local table_data
    table_data=$(echo "$shortage_data" | awk -F'|' '{
        printf "%-11s|%-18s|%-20s|%-4s|%-7s|%-8s|%-8s\n",
            $1, substr($2,1,18), substr($3,1,20), $4, $5, $6, $7
    }')

    render_table "11 18 20 4 7 8 8" "Roll Number|Student Name|Department|Sem|Total|Attended|Percent" "$table_data"

    printf "\n"
    draw_alert "WARNING" "Action Notice: Students listed above are subject to academic counseling and potential exam debarment."

    pause_key
}
