#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Academic & Transcript UI
# Powered by Linux Commands: awk, grep, cut, printf
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=frontend/ui_components.sh
[ -f "$SCRIPT_DIR/ui_components.sh" ] && . "$SCRIPT_DIR/ui_components.sh"
# shellcheck source=dependencies/validators.sh
[ -f "$ROOT_DIR/dependencies/validators.sh" ] && . "$ROOT_DIR/dependencies/validators.sh"
# shellcheck source=backend/students.sh
[ -f "$ROOT_DIR/backend/students.sh" ] && . "$ROOT_DIR/backend/students.sh"
# shellcheck source=backend/academics.sh
[ -f "$ROOT_DIR/backend/academics.sh" ] && . "$ROOT_DIR/backend/academics.sh"

# Enter Course Marks
ui_enter_marks() {
    clear_screen
    render_header
    render_status_bar

    if ! is_faculty; then
        draw_alert "DANGER" "Access Denied: Only Faculty and Administrators can evaluate course marks."
        pause_key
        return
    fi

    c_println "$CLR_PRIMARY" "${BOLD}  COURSE EVALUATION & MARKS RECORDING PORTAL${RESET}"
    c_println "$CLR_MUTED" "  Enter internal assessments and end-semester external exam marks.\n"

    local roll
    prompt_input "Student Roll Number" "roll" "" "validate_roll_no"

    local student_row
    student_row=$(get_student_by_roll "$roll")
    if [ -z "$student_row" ]; then
        draw_alert "DANGER" "Student '$roll' does not exist."
        pause_key
        return
    fi

    local student_name student_dept student_sem
    student_name=$(echo "$student_row" | cut -d',' -f2)
    student_dept=$(echo "$student_row" | cut -d',' -f8)
    student_sem=$(echo "$student_row" | cut -d',' -f9)

    printf "  Student: ${BOLD}%s${RESET} | Department: %s | Semester: %s\n\n" "$student_name" "$student_dept" "$student_sem"

    local course_code course_name credits internal external sem
    prompt_input "Course Code (e.g. CS601, EE402)" "course_code" "CS601" ""
    prompt_input "Course / Subject Title" "course_name" "Distributed Systems" ""
    prompt_input "Course Credit Hours [1-6]" "credits" "4" ""
    prompt_input "Internal Assessment Marks [0-30 or 0-50]" "internal" "28" "validate_marks"
    prompt_input "External Exam Marks [0-70 or 0-50]" "external" "64" "validate_marks"
    prompt_input "Academic Semester [1-8]" "sem" "$student_sem" "validate_semester"

    if add_course_mark "$roll" "$course_code" "$course_name" "$credits" "$internal" "$external" "$sem"; then
        draw_alert "SUCCESS" "Marks and Grade recorded successfully for '$course_code: $course_name'!"
    else
        draw_alert "DANGER" "Failed to store academic record."
    fi

    pause_key
}

# Generate and Render Official Grade Transcript
ui_view_transcript() {
    clear_screen
    render_header
    render_status_bar

    c_println "$CLR_PRIMARY" "${BOLD}  ACADEMIC TRANSCRIPT & GRADE REPORT GENERATOR${RESET}"
    c_println "$CLR_MUTED" "  Official semester-wise grade sheet with credit evaluation and CGPA.\n"

    printf "  ${CLR_PRIMARY}Enter Student Roll Number: ${RESET}"
    read -r roll

    local student_row
    student_row=$(get_student_by_roll "$roll")

    if [ -z "$student_row" ]; then
        draw_alert "DANGER" "Student '$roll' not found."
        pause_key
        return
    fi

    local name dept sem
    name=$(echo "$student_row" | cut -d',' -f2)
    dept=$(echo "$student_row" | cut -d',' -f8)
    sem=$(echo "$student_row" | cut -d',' -f9)

    local courses
    courses=$(get_student_courses "$roll")

    if [ -z "$courses" ]; then
        draw_alert "INFO" "No examination or course records found for student '$name' ($roll)."
        pause_key
        return
    fi

    local cgpa standing
    cgpa=$(calculate_cgpa "$roll")
    standing=$(get_academic_standing "$cgpa")

    local term_w
    term_w=$(get_term_width)

    printf "\n"
    center_text "${BOLD}${CLR_PRIMARY}╔══════════════════════════════════════════════════════════════════════════╗${RESET}" "$term_w"
    center_text "${BOLD}${CLR_PRIMARY}║                    OFFICIAL GRADE POINT TRANSCRIPT                       ║${RESET}" "$term_w"
    center_text "${BOLD}${CLR_PRIMARY}╚══════════════════════════════════════════════════════════════════════════╝${RESET}" "$term_w"
    printf "\n"

    printf "  Student Name: ${BOLD}%-28s${RESET} Roll Number: ${BOLD}%-15s${RESET}\n" "$name" "$roll"
    printf "  Department:   %-28s Current Sem:  %-15s\n" "$dept" "Semester $sem"
    echo "  ──────────────────────────────────────────────────────────────────────────"

    # Format course table
    local table_data
    table_data=$(echo "$courses" | awk -F',' '{
        printf "%-8s|%-26s|%-4s|%-5s|%-5s|%-5s|%-3s|%-4s|%-3s\n",
            $2, substr($3,1,26), $4, $5, $6, $7, $8, $9, $10
    }')

    render_table "8 26 4 5 5 5 3 4 3" "Code|Course Title|Cred|Int|Ext|Tot|Grd|Pts|Sem" "$table_data"

    printf "\n"
    echo "  ╭────────────────────────────────────────────────────────────────────────╮"
    printf "  │  ${BOLD}CUMULATIVE GRADE POINT AVERAGE (CGPA):${RESET} ${CLR_GOLD}${BOLD}%-10s${RESET} (Scale: 10.0)      │\n" "${cgpa}"
    printf "  │  Academic Classification: ${BOLD}%-44s${RESET} │\n" "$standing"
    echo "  ╰────────────────────────────────────────────────────────────────────────╯"

    # Optional export to text file
    printf "\n  ${CLR_PRIMARY}Export this Transcript to exports/ transcript file? [y/N]: ${RESET}"
    read -r exp_choice
    if [[ "$exp_choice" =~ ^[Yy]$ ]]; then
        local exp_file="exports/transcript_${roll}_$(date +%Y%m%d).txt"
        {
            echo "================================================================================"
            echo "                     APEX UNIVERSITY - OFFICIAL TRANSCRIPT                      "
            echo "================================================================================"
            echo "Student Name : $name"
            echo "Roll Number  : $roll"
            echo "Department   : $dept"
            echo "Generated On : $(date '+%Y-%m-%d %H:%M:%S')"
            echo "--------------------------------------------------------------------------------"
            printf "%-10s | %-30s | %-6s | %-6s | %-6s | %-4s\n" "Code" "Course Title" "Cred" "Marks" "Grade" "Pts"
            echo "--------------------------------------------------------------------------------"
            echo "$courses" | awk -F',' '{ printf "%-10s | %-30s | %-6s | %-6s | %-6s | %-4s\n", $2, substr($3,1,30), $4, $7, $8, $9 }'
            echo "--------------------------------------------------------------------------------"
            echo "Cumulative CGPA : $cgpa / 10.0"
            echo "Classification  : $standing"
            echo "================================================================================"
        } > "$exp_file"
        draw_alert "SUCCESS" "Transcript successfully exported to '$exp_file'!"
    fi

    pause_key
}
