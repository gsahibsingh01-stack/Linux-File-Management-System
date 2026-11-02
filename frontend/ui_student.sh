#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Student Profile & Records UI
# Powered by Linux Commands: awk, grep, cut, printf, tput
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
# shellcheck source=backend/attendance.sh
[ -f "$ROOT_DIR/backend/attendance.sh" ] && . "$ROOT_DIR/backend/attendance.sh"
# shellcheck source=backend/fees.sh
[ -f "$ROOT_DIR/backend/fees.sh" ] && . "$ROOT_DIR/backend/fees.sh"

# List All Enrolled Students in a responsive terminal table
ui_list_students() {
    clear_screen
    render_header
    render_status_bar

    c_println "$CLR_PRIMARY" "${BOLD}  STUDENT REGISTRY & ENROLLMENT DIRECTORY${RESET}"
    c_println "$CLR_MUTED" "  All registered student accounts across university academic programs.\n"

    local raw_data
    raw_data=$(get_all_students)

    if [ -z "$raw_data" ]; then
        draw_alert "INFO" "No students found in the database. Use 'Add Student' to create records."
        pause_key
        return
    fi

    # Format pipe-delimited data for render_table
    local table_data
    table_data=$(echo "$raw_data" | awk -F',' '{
        printf "%-11s|%-18s|%-22s|%-4s|%-10s|%-12s\n", 
            $1, substr($2,1,18), substr($8,1,22), $9, $11, $10
    }')

    render_table "11 18 22 4 10 12" "Roll Number|Full Name|Department|Sem|Status|Enrolled On" "$table_data"

    printf "\n  ${CLR_MUTED}Total Records: $(get_student_count) students${RESET}\n"
    pause_key
}

# Add a New Student
ui_add_student() {
    clear_screen
    render_header
    render_status_bar

    if ! can_modify; then
        draw_alert "DANGER" "Access Denied: Only Administrator or Faculty roles can add student records."
        pause_key
        return
    fi

    c_println "$CLR_SUCCESS" "${BOLD}  NEW STUDENT ENROLLMENT ADMISSION FORM${RESET}"
    c_println "$CLR_MUTED" "  Enter student demographic, academic, and contact information.\n"

    local roll name email phone dob gender blood dept sem status

    prompt_input "Roll Number (e.g. STU2026001)" "roll" "" "validate_roll_no"
    if roll_number_exists "$roll"; then
        draw_alert "DANGER" "Roll Number '$roll' already exists in the system!"
        pause_key
        return
    fi

    prompt_input "Student Full Legal Name" "name" "" "validate_name"
    prompt_input "Institutional / Personal Email" "email" "${roll,,}@university.edu" "validate_email"
    prompt_input "Emergency Contact Phone Number" "phone" "+1-555-0199" "validate_phone"
    prompt_input "Date of Birth (YYYY-MM-DD)" "dob" "2004-06-15" "validate_date"
    prompt_input "Gender (M / F / Other)" "gender" "M" "validate_gender"
    prompt_input "Blood Group (e.g. O+, A+, B+, AB-)" "blood" "O+" "validate_blood_group"
    
    printf "\n  ${CLR_ACCENT}Select Department / Branch:${RESET}\n"
    echo "  [1] Computer Science           [4] Civil Engineering"
    echo "  [2] Electrical Engineering     [5] Mechanical Engineering"
    echo "  [3] Information Technology     [6] Biomedical Engineering"
    prompt_input "Choose Option [1-6]" "dept_choice" "1" ""
    case "$dept_choice" in
        1) dept="Computer Science" ;;
        2) dept="Electrical Engineering" ;;
        3) dept="Information Technology" ;;
        4) dept="Civil Engineering" ;;
        5) dept="Mechanical Engineering" ;;
        6) dept="Biomedical Engineering" ;;
        *) dept="Computer Science" ;;
    esac

    prompt_input "Current Semester [1-8]" "sem" "1" "validate_semester"
    prompt_input "Initial Status [ACTIVE, ON LEAVE]" "status" "ACTIVE" "validate_status"

    printf "\n"
    draw_alert "WARNING" "Review and Confirm: Enroll Student '$name' ($roll) into '$dept' Semester $sem?"
    printf "  ${CLR_PRIMARY}Proceed with Registration? [Y/n]: ${RESET}"
    read -r confirm
    confirm=${confirm:-Y}

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if add_student "$roll" "$name" "$email" "$phone" "$dob" "$gender" "$blood" "$dept" "$sem" "$(date +%Y-%m-%d)" "$status"; then
            draw_alert "SUCCESS" "Student record for '$name' ($roll) successfully registered!"
        else
            draw_alert "DANGER" "Failed to save student record to database."
        fi
    else
        draw_alert "INFO" "Registration aborted by user."
    fi

    pause_key
}

# Search Students Interactive View
ui_search_students() {
    clear_screen
    render_header
    render_status_bar

    c_println "$CLR_PRIMARY" "${BOLD}  STUDENT SEARCH & FILTER ENGINE${RESET}"
    c_println "$CLR_MUTED" "  Search by Roll Number, Full Name, Department, or Status.\n"

    printf "  ${CLR_PRIMARY}Enter Search Keyword: ${RESET}"
    read -r query

    if [ -z "$query" ]; then
        draw_alert "WARNING" "No search keyword provided."
        pause_key
        return
    fi

    local results
    results=$(search_students "$query")

    if [ -z "$results" ]; then
        draw_alert "INFO" "No records matching query: '$query'"
        pause_key
        return
    fi

    local count
    count=$(echo "$results" | wc -l)
    printf "\n  ${CLR_SUCCESS}${BOLD}Found %d matching student record(s):${RESET}\n\n" "$count"

    local table_data
    table_data=$(echo "$results" | awk -F',' '{
        printf "%-11s|%-18s|%-22s|%-4s|%-10s|%-12s\n", 
            $1, substr($2,1,18), substr($8,1,22), $9, $11, $10
    }')

    render_table "11 18 22 4 10 12" "Roll Number|Full Name|Department|Sem|Status|Enrolled On" "$table_data"

    printf "\n  ${CLR_PRIMARY}Would you like to inspect a full student profile card? [Enter Roll No or press Enter to skip]: ${RESET}"
    read -r inspect_roll
    if [ -n "$inspect_roll" ]; then
        ui_view_student_card "$inspect_roll"
    fi
}

# View Detailed Student Profile Card (Combines Academics, Attendance, and Fees)
ui_view_student_card() {
    local target_roll="$1"

    if [ -z "$target_roll" ]; then
        clear_screen
        render_header
        render_status_bar
        printf "\n  ${CLR_PRIMARY}Enter Student Roll Number to inspect: ${RESET}"
        read -r target_roll
    fi

    local student_row
    student_row=$(get_student_by_roll "$target_roll")

    if [ -z "$student_row" ]; then
        draw_alert "DANGER" "Student with Roll Number '$target_roll' not found."
        pause_key
        return
    fi

    clear_screen
    render_header
    render_status_bar

    local roll name email phone dob gender blood dept sem enroll status
    IFS=',' read -r roll name email phone dob gender blood dept sem enroll status <<< "$student_row"

    # Fetch Attendance
    local att_row att_total att_attended att_pct
    att_row=$(get_attendance_record "$roll")
    att_total=$(echo "$att_row" | cut -d',' -f2)
    att_attended=$(echo "$att_row" | cut -d',' -f3)
    att_pct=$(echo "$att_row" | cut -d',' -f4)
    att_pct="${att_pct:-N/A}"

    # Fetch CGPA & Standing
    local cgpa standing
    cgpa=$(calculate_cgpa "$roll")
    standing=$(get_academic_standing "$cgpa")

    # Fetch Fee Status
    local fee_row fee_total fee_paid fee_due fee_status
    fee_row=$(get_fee_record "$roll")
    fee_total=$(echo "$fee_row" | cut -d',' -f4)
    fee_paid=$(echo "$fee_row" | cut -d',' -f5)
    fee_due=$(echo "$fee_row" | cut -d',' -f6)
    fee_status=$(echo "$fee_row" | cut -d',' -f7)
    fee_status="${fee_status:-UNKNOWN}"

    local term_w
    term_w=$(get_term_width)

    printf "\n"
    center_text "${BOLD}${CLR_PRIMARY}══════════════════════ OFFICIAL STUDENT DOSSIER ══════════════════════${RESET}" "$term_w"
    printf "\n"

    echo "  ╭────────────────────────────────────────────────────────────────────────────╮"
    printf "  │  ${BOLD}%-40s${RESET} Status: %-19b │\n" "$name ($roll)" "$(get_status_badge "$status")"
    printf "  │  Department: %-28s Semester: %-21s │\n" "$dept" "$sem"
    echo "  ├────────────────────────────────────────────────────────────────────────────┤"
    echo "  │  PERSONAL INFORMATION:                                                     │"
    printf "  │    • Email:        %-54s │\n" "$email"
    printf "  │    • Phone:        %-20s Date of Birth: %-19s │\n" "$phone" "$dob"
    printf "  │    • Gender:       %-20s Blood Group:   %-19s │\n" "$gender" "$blood"
    printf "  │    • Enrolled:     %-54s │\n" "$enroll"
    echo "  ├────────────────────────────────────────────────────────────────────────────┤"
    echo "  │  ACADEMIC METRICS:                                                         │"
    printf "  │    • Cumulative CGPA:   ${BOLD}${CLR_GOLD}%-14s${RESET} Standing: %-24s │\n" "${cgpa} / 10.0" "$standing"
    echo "  ├────────────────────────────────────────────────────────────────────────────┤"
    echo "  │  ATTENDANCE & FINANCIAL SUMMARY:                                           │"
    local att_color="$CLR_SUCCESS"
    if [ "${att_pct%.*}" -lt 75 ] 2>/dev/null; then att_color="$CLR_DANGER"; fi
    printf "  │    • Attendance Rate:   ${att_color}${BOLD}%-15s${RESET} (${att_attended:-0}/${att_total:-0} Classes Attended)     │\n" "${att_pct}%"
    printf "  │    • Fee Ledger:        Paid: \$%-10s Due: \$%-12s Status: %-8s │\n" "${fee_paid:-0.00}" "${fee_due:-0.00}" "$fee_status"
    echo "  ╰────────────────────────────────────────────────────────────────────────────╯"
    printf "\n"

    pause_key
}

# Update an existing Student Record
ui_update_student() {
    clear_screen
    render_header
    render_status_bar

    if ! can_modify; then
        draw_alert "DANGER" "Access Denied: Only Administrator or Faculty roles can modify student records."
        pause_key
        return
    fi

    c_println "$CLR_PRIMARY" "${BOLD}  UPDATE STUDENT RECORD INFORMATION${RESET}"
    c_println "$CLR_MUTED" "  Modify demographic, contact, department, semester, or status details.\n"

    printf "  ${CLR_PRIMARY}Enter Roll Number of Student to Update: ${RESET}"
    read -r roll

    local student_row
    student_row=$(get_student_by_roll "$roll")

    if [ -z "$student_row" ]; then
        draw_alert "DANGER" "Student with Roll Number '$roll' was not found."
        pause_key
        return
    fi

    local cur_roll cur_name cur_email cur_phone cur_dob cur_gender cur_blood cur_dept cur_sem cur_enroll cur_status
    IFS=',' read -r cur_roll cur_name cur_email cur_phone cur_dob cur_gender cur_blood cur_dept cur_sem cur_enroll cur_status <<< "$student_row"

    printf "\n  ${CLR_MUTED}Current Record for %s (${cur_roll}):${RESET}\n" "$cur_name"
    printf "  Name: %s | Dept: %s | Sem: %s | Status: %s\n\n" "$cur_name" "$cur_dept" "$cur_sem" "$cur_status"

    local new_name new_email new_phone new_dob new_gender new_blood new_dept new_sem new_status

    prompt_input "Full Name" "new_name" "$cur_name" "validate_name"
    prompt_input "Email" "new_email" "$cur_email" "validate_email"
    prompt_input "Phone" "new_phone" "$cur_phone" "validate_phone"
    prompt_input "Date of Birth" "new_dob" "$cur_dob" "validate_date"
    prompt_input "Gender" "new_gender" "$cur_gender" "validate_gender"
    prompt_input "Blood Group" "new_blood" "$cur_blood" "validate_blood_group"
    prompt_input "Department" "new_dept" "$cur_dept" ""
    prompt_input "Semester [1-8]" "new_sem" "$cur_sem" "validate_semester"
    prompt_input "Status [ACTIVE, ON LEAVE, GRADUATED, SUSPENDED]" "new_status" "$cur_status" "validate_status"

    if update_student "$roll" "$new_name" "$new_email" "$new_phone" "$new_dob" "$new_gender" "$new_blood" "$new_dept" "$new_sem" "$new_status"; then
        draw_alert "SUCCESS" "Student record for '$roll' updated successfully!"
    else
        draw_alert "DANGER" "Failed to update record in database."
    fi

    pause_key
}

# Delete & Archive Student Record
ui_delete_student() {
    clear_screen
    render_header
    render_status_bar

    if ! is_admin; then
        draw_alert "DANGER" "Security Restriction: Student removal requires Administrator privileges."
        pause_key
        return
    fi

    c_println "$CLR_DANGER" "${BOLD}  STUDENT ARCHIVE & DELETION DISCIPLINARY INTERFACE${RESET}"
    c_println "$CLR_MUTED" "  Safe deletion with permanent backup archive record logging.\n"

    printf "  ${CLR_DANGER}Enter Roll Number of Student to Remove: ${RESET}"
    read -r roll

    local student_row
    student_row=$(get_student_by_roll "$roll")

    if [ -z "$student_row" ]; then
        draw_alert "DANGER" "Student with Roll Number '$roll' does not exist."
        pause_key
        return
    fi

    local name dept
    name=$(echo "$student_row" | cut -d',' -f2)
    dept=$(echo "$student_row" | cut -d',' -f8)

    draw_alert "WARNING" "CONFIRMATION REQUIRED: Remove '${name}' (${roll}) from ${dept}?\nThis record will be moved to the archival repository."

    printf "  Enter Deletion / Archival Reason: "
    read -r reason
    reason="${reason:-Graduation / Clearance}"

    printf "  Are you ABSOLUTELY SURE you want to delete this student? [type 'DELETE' to confirm]: "
    read -r confirm

    if [ "$confirm" = "DELETE" ]; then
        if delete_student "$roll" "$reason"; then
            draw_alert "SUCCESS" "Student '$roll' successfully removed and archived to data/archive.csv."
        else
            draw_alert "DANGER" "Error during deletion process."
        fi
    else
        draw_alert "INFO" "Deletion canceled. No records were modified."
    fi

    pause_key
}
