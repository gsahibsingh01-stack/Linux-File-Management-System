#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Authentication UI
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=frontend/ui_components.sh
[ -f "$SCRIPT_DIR/ui_components.sh" ] && . "$SCRIPT_DIR/ui_components.sh"
# shellcheck source=backend/auth.sh
[ -f "$ROOT_DIR/backend/auth.sh" ] && . "$ROOT_DIR/backend/auth.sh"

show_login_screen() {
    while true; do
        clear_screen
        render_header

        local term_w
        term_w=$(get_term_width)

        printf "\n"
        center_text "${BOLD}${CLR_PRIMARY}SECURE USER AUTHENTICATION & ACCESS CONTROL${RESET}" "$term_w"
        center_text "${CLR_MUTED}Please log in with your university credentials or select a demo account${RESET}" "$term_w"
        printf "\n"

        echo "  ╭──────────────────────────────────────────────────────────────────────────╮"
        echo "  │  Select Authentication Mode:                                             │"
        echo "  │                                                                          │"
        echo "  │  [1] Custom Login (Enter Username & Password)                            │"
        echo "  │  [2] Quick Login as Administrator    (admin   / admin123)   • Full Access│"
        echo "  │  [3] Quick Login as Faculty Member   (faculty / faculty123) • Academic   │"
        echo "  │  [4] Quick Login as Guest Student    (guest   / guest123)   • Read Only  │"
        echo "  │                                                                          │"
        echo "  │  [0] Exit to Linux Shell                                                 │"
        echo "  ╰──────────────────────────────────────────────────────────────────────────╯"
        printf "\n"

        printf "  ${CLR_PRIMARY}${BOLD}Select Option [1-4, 0]: ${RESET}"
        read -r choice

        case "$choice" in
            1)
                printf "\n  ${CLR_PRIMARY}Username: ${RESET}"
                read -r uname
                printf "  ${CLR_PRIMARY}Password: ${RESET}"
                # Read password silently
                read -s -r upass
                printf "\n\n"

                if authenticate_user "$uname" "$upass"; then
                    draw_alert "SUCCESS" "Authentication successful! Welcome, $(get_current_name)."
                    sleep 1
                    return 0
                else
                    draw_alert "DANGER" "Invalid username or password. Access Denied."
                    pause_key
                fi
                ;;
            2)
                if authenticate_user "admin" "admin123"; then
                    draw_alert "SUCCESS" "Signed in as Chief Registrar (Administrator)."
                    sleep 0.8
                    return 0
                fi
                ;;
            3)
                if authenticate_user "faculty" "faculty123"; then
                    draw_alert "SUCCESS" "Signed in as Prof. Alan Turing (Faculty Member)."
                    sleep 0.8
                    return 0
                fi
                ;;
            4)
                if authenticate_user "guest" "guest123"; then
                    draw_alert "SUCCESS" "Signed in as Guest Auditor (Read-Only Mode)."
                    sleep 0.8
                    return 0
                fi
                ;;
            0|q|Q)
                printf "\n${CLR_MUTED}Exiting Apex Student Record Management System. Goodbye!${RESET}\n\n"
                exit 0
                ;;
            *)
                draw_alert "WARNING" "Invalid selection. Please choose an option from the menu."
                pause_key
                ;;
        esac
    done
}
