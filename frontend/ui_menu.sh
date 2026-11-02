#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Master Menu & Navigation Router
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source all UI and backend modules
# shellcheck source=frontend/ui_components.sh
. "$SCRIPT_DIR/ui_components.sh"
# shellcheck source=frontend/ui_auth.sh
. "$SCRIPT_DIR/ui_auth.sh"
# shellcheck source=frontend/ui_student.sh
. "$SCRIPT_DIR/ui_student.sh"
# shellcheck source=frontend/ui_academic.sh
. "$SCRIPT_DIR/ui_academic.sh"
# shellcheck source=frontend/ui_attendance.sh
. "$SCRIPT_DIR/ui_attendance.sh"
# shellcheck source=frontend/ui_fees.sh
. "$SCRIPT_DIR/ui_fees.sh"
# shellcheck source=frontend/ui_analytics.sh
. "$SCRIPT_DIR/ui_analytics.sh"
# shellcheck source=backend/backup.sh
. "$ROOT_DIR/backend/backup.sh"

run_main_menu() {
    while true; do
        clear_screen
        render_header
        render_status_bar

        local cur_role
        cur_role=$(get_current_role)

        echo "  ╭────────────────────────────────────────────────────────────────────────────╮"
        echo "  │  STUDENT RECORDS:                 │  ACADEMICS & ATTENDANCE:               │"
        echo "  │   [1] List All Enrolled Students  │   [7] Record Course Marks & Grades     │"
        echo "  │   [2] Enroll / Add New Student    │   [8] Generate Official Transcript     │"
        echo "  │   [3] Search Student Directory    │   [9] View Attendance Register         │"
        echo "  │   [4] Inspect Student Profile     │  [10] Update Attendance Session        │"
        echo "  │   [5] Update Student Record       │  [11] Attendance Shortage Board (<75%) │"
        echo "  │   [6] Archive / Delete Student    │                                        │"
        echo "  ├───────────────────────────────────┼────────────────────────────────────────┤"
        echo "  │  BURSAR & FEES:                   │  ANALYTICS & SYSTEM TOOLS:             │"
        echo "  │  [12] View Student Fee Ledger     │  [15] Visual Charts & Honors Rank List │"
        echo "  │  [13] Collect / Process Payment   │  [16] Create System Backup (.tar.gz)   │"
        echo "  │  [14] Fee Defaulters Overdue List │  [17] Export Master University Report  │"
        echo "  │                                   │  [18] Switch User Account / Sign Out   │"
        echo "  │                                   │   [0] Exit to Linux Terminal           │"
        echo "  ╰────────────────────────────────────────────────────────────────────────────╯"
        printf "\n"

        printf "  ${CLR_PRIMARY}${BOLD}Enter Command Number [1-18, 0]: ${RESET}"
        read -r choice

        case "$choice" in
            1) ui_list_students ;;
            2) ui_add_student ;;
            3) ui_search_students ;;
            4) ui_view_student_card ;;
            5) ui_update_student ;;
            6) ui_delete_student ;;
            7) ui_enter_marks ;;
            8) ui_view_transcript ;;
            9) ui_view_attendance ;;
            10) ui_update_attendance ;;
            11) ui_shortage_board ;;
            12) ui_view_fees ;;
            13) ui_pay_fee ;;
            14) ui_fee_defaulters ;;
            15) ui_view_analytics ;;
            16)
                if is_admin; then
                    local bk_info
                    bk_info=$(create_backup)
                    if [ $? -eq 0 ]; then
                        local bk_file bk_size
                        bk_file=$(echo "$bk_info" | cut -d'|' -f1)
                        bk_size=$(echo "$bk_info" | cut -d'|' -f2)
                        draw_alert "SUCCESS" "Compressed database backup created successfully!\nFile: ${bk_file} (${bk_size})"
                    fi
                else
                    draw_alert "DANGER" "Permission Denied: System backup requires Administrator privileges."
                fi
                pause_key
                ;;
            17)
                local rep_file
                rep_file=$(generate_master_report "txt")
                draw_alert "SUCCESS" "Official master report generated successfully!\nFile: ${rep_file}"
                pause_key
                ;;
            18)
                logout_user
                draw_alert "INFO" "You have signed out."
                sleep 0.8
                show_login_screen
                ;;
            0|q|Q|exit)
                logout_user
                printf "\n  ${CLR_MUTED}Thank you for using Apex Student Record Management System. Goodbye!${RESET}\n\n"
                exit 0
                ;;
            *)
                draw_alert "WARNING" "Invalid selection '$choice'. Please choose a valid command number [1-18, 0]."
                sleep 1
                ;;
        esac
    done
}
