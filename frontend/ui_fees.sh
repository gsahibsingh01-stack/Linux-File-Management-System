#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Financial & Fee Ledger UI
# Powered by Linux Commands: awk, grep, cut, printf
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=frontend/ui_components.sh
[ -f "$SCRIPT_DIR/ui_components.sh" ] && . "$SCRIPT_DIR/ui_components.sh"
# shellcheck source=backend/students.sh
[ -f "$ROOT_DIR/backend/students.sh" ] && . "$ROOT_DIR/backend/students.sh"
# shellcheck source=backend/fees.sh
[ -f "$ROOT_DIR/backend/fees.sh" ] && . "$ROOT_DIR/backend/fees.sh"

# View Complete Fee Ledger
ui_view_fees() {
    clear_screen
    render_header
    render_status_bar

    c_println "$CLR_PRIMARY" "${BOLD}  BURSAR'S OFFICE & STUDENT FINANCIAL LEDGER${RESET}"
    c_println "$CLR_MUTED" "  Tuition fee schedules, payment receipts, and balance dues.\n"

    local fin_summary exp_tot col_tot due_tot def_count
    fin_summary=$(get_fee_analytics)
    exp_tot=$(echo "$fin_summary" | cut -d'|' -f1)
    col_tot=$(echo "$fin_summary" | cut -d'|' -f2)
    due_tot=$(echo "$fin_summary" | cut -d'|' -f3)
    def_count=$(echo "$fin_summary" | cut -d'|' -f4)

    printf "  ${CLR_ACCENT}Total Expected:${RESET} \$%s  ${CLR_MUTED}•${RESET}  ${CLR_SUCCESS}Collected:${RESET} \$%s  ${CLR_MUTED}•${RESET}  ${CLR_DANGER}Outstanding Dues:${RESET} \$%s (%d Defaulters)\n\n" \
        "$exp_tot" "$col_tot" "$due_tot" "$def_count"

    if [ ! -f "$DATA_DIR/fees.csv" ]; then
        draw_alert "INFO" "No fee records found in system."
        pause_key
        return
    fi

    local table_data
    table_data=$(awk -F',' '
        NR == FNR {
            if (FNR > 1) {
                name[$1] = $2;
            }
            next;
        }
        FNR > 1 {
            roll = $2;
            n = (roll in name) ? substr(name[roll], 1, 16) : "-";
            rec = $1;
            cat = substr($3, 1, 16);
            tot = sprintf("$%.2f", $4+0);
            paid = sprintf("$%.2f", $5+0);
            due = sprintf("$%.2f", $6+0);
            st = $7;
            printf "%-11s|%-11s|%-16s|%-16s|%-9s|%-9s|%-9s|%-8s\n",
                rec, roll, n, cat, tot, paid, due, st
        }
    ' "$DATA_DIR/students.csv" "$DATA_DIR/fees.csv")

    render_table "11 11 16 16 9 9 9 8" "Receipt|Roll Number|Student Name|Fee Category|Total|Paid|Due|Status" "$table_data"

    pause_key
}

# Process Student Fee Payment
ui_pay_fee() {
    clear_screen
    render_header
    render_status_bar

    if ! is_faculty; then
        draw_alert "DANGER" "Access Denied: Only Bursar / Administrator can record fee payments."
        pause_key
        return
    fi

    c_println "$CLR_SUCCESS" "${BOLD}  FEE COLLECTION & PAYMENT PROCESSING${RESET}"
    c_println "$CLR_MUTED" "  Accept student tuition, hostel, or exam fee remittances.\n"

    local roll
    prompt_input "Enter Student Roll Number" "roll" "" "validate_roll_no"

    local fee_rec
    fee_rec=$(get_fee_record "$roll")
    if [ -z "$fee_rec" ]; then
        draw_alert "DANGER" "No fee account found for student '$roll'."
        pause_key
        return
    fi

    local student_row student_name
    student_row=$(get_student_by_roll "$roll")
    student_name=$(echo "$student_row" | cut -d',' -f2)

    local cur_rec_no cur_cat cur_tot cur_paid cur_due cur_status
    cur_rec_no=$(echo "$fee_rec" | cut -d',' -f1)
    cur_cat=$(echo "$fee_rec" | cut -d',' -f3)
    cur_tot=$(echo "$fee_rec" | cut -d',' -f4)
    cur_paid=$(echo "$fee_rec" | cut -d',' -f5)
    cur_due=$(echo "$fee_rec" | cut -d',' -f6)
    cur_status=$(echo "$fee_rec" | cut -d',' -f7)

    printf "  Student: ${BOLD}%s${RESET} ($roll) | Category: %s\n" "$student_name" "$cur_cat"
    printf "  Total Fee: \$%s | Amount Paid: \$%s | ${CLR_DANGER}Outstanding Due: \$%s${RESET} | Status: %s\n\n" \
        "$cur_tot" "$cur_paid" "$cur_due" "$cur_status"

    if [ "$(printf "%.0f" "$cur_due" 2>/dev/null || echo 0)" -le 0 ]; then
        draw_alert "SUCCESS" "This student has zero outstanding fee balance ($cur_status)."
        pause_key
        return
    fi

    local pay_amount
    prompt_input "Enter Payment Amount (USD)" "pay_amount" "$cur_due" "validate_amount"

    local pay_res
    pay_res=$(record_fee_payment "$roll" "$pay_amount")

    if [ $? -eq 0 ] && [ -n "$pay_res" ]; then
        local new_rec new_paid new_due new_st
        new_rec=$(echo "$pay_res" | cut -d'|' -f1)
        new_paid=$(echo "$pay_res" | cut -d'|' -f2)
        new_due=$(echo "$pay_res" | cut -d'|' -f3)
        new_st=$(echo "$pay_res" | cut -d'|' -f4)

        draw_alert "SUCCESS" "Payment of \$${pay_amount} recorded!\nReceipt Number: ${new_rec}\nUpdated Balance: \$${new_due} (${new_st})"

        # Print Payment Voucher
        echo "  ╭────────────────────────────────────────────────────────────╮"
        echo "  │            APEX UNIVERSITY - OFFICIAL FEE RECEIPT          │"
        echo "  ├────────────────────────────────────────────────────────────┤"
        printf "  │  Receipt No:    %-42s │\n" "$new_rec"
        printf "  │  Date:          %-42s │\n" "$(date '+%Y-%m-%d %H:%M:%S')"
        printf "  │  Student:       %-42s │\n" "$student_name ($roll)"
        printf "  │  Amount Paid:   \$%-41s │\n" "$pay_amount"
        printf "  │  Remaining Due: \$%-41s │\n" "$new_due"
        printf "  │  Status:        %-42s │\n" "$new_st"
        echo "  ╰────────────────────────────────────────────────────────────╯"
    else
        draw_alert "DANGER" "Failed to process fee transaction."
    fi

    pause_key
}

# Fee Defaulters List
ui_fee_defaulters() {
    clear_screen
    render_header
    render_status_bar

    c_println "$CLR_DANGER" "${BOLD}  OUTSTANDING FEE DEFAULTERS & PENDING DUES REPORT${RESET}"
    c_println "$CLR_MUTED" "  Students with overdue tuition, library, lab, or hostel balances.\n"

    local defaulters_data
    defaulters_data=$(get_fee_defaulters)

    if [ -z "$defaulters_data" ]; then
        draw_alert "SUCCESS" "Superb! All students have fully cleared their tuition dues."
        pause_key
        return
    fi

    local table_data
    table_data=$(echo "$defaulters_data" | awk -F'|' '{
        printf "%-11s|%-18s|%-18s|%-15s|%-10s|%-10s|%-8s\n",
            $1, substr($2,1,18), substr($3,1,18), $4, $5, $6, $7
    }')

    render_table "11 18 18 15 10 10 8" "Roll Number|Student Name|Department|Contact Phone|Total Fee|Pending Due|Status" "$table_data"

    pause_key
}
