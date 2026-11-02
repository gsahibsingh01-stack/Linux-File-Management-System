#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Financial & Fee Ledger Service
# Powered by Linux Commands: awk, grep, date, cut, tr
# ==============================================================================

DATA_DIR="${DATA_DIR:-data}"
FEES_FILE="$DATA_DIR/fees.csv"
STUDENTS_FILE="$DATA_DIR/students.csv"

# Fetch student fee status
# Output: receipt_no,roll_no,fee_type,total_fee,paid_amount,due_amount,status,payment_date
get_fee_record() {
    local roll="$1"
    if [ ! -f "$FEES_FILE" ]; then return 1; fi

    awk -F',' -v r="$roll" '
        NR > 1 && tolower($2) == tolower(r) {
            print $0;
            exit;
        }
    ' "$FEES_FILE"
}

# Process fee payment
record_fee_payment() {
    local roll="$1"
    local payment_amount="$2"
    local payment_date
    payment_date=$(date +%Y-%m-%d)

    if [ ! -f "$FEES_FILE" ]; then return 1; fi

    local rec
    rec=$(get_fee_record "$roll")
    if [ -z "$rec" ]; then
        echo "ERROR: No fee record exists for student '$roll'." >&2
        return 1
    fi

    local current_receipt current_total current_paid current_due
    current_receipt=$(echo "$rec" | cut -d',' -f1)
    current_total=$(echo "$rec" | cut -d',' -f4)
    current_paid=$(echo "$rec" | cut -d',' -f5)
    current_due=$(echo "$rec" | cut -d',' -f6)

    # Compute new amounts using awk
    local calc_res
    calc_res=$(awk -v tot="$current_total" -v cur_p="$current_paid" -v pay="$payment_amount" 'BEGIN {
        new_paid = cur_p + pay;
        new_due = tot - new_paid;
        if (new_due < 0) new_due = 0;
        status = (new_due <= 0.05) ? "PAID" : "PARTIAL";
        printf "%.2f|%.2f|%s\n", new_paid, new_due, status;
    }')

    local new_paid new_due new_status
    new_paid=$(echo "$calc_res" | cut -d'|' -f1)
    new_due=$(echo "$calc_res" | cut -d'|' -f2)
    new_status=$(echo "$calc_res" | cut -d'|' -f3)

    # Generate updated receipt reference
    local new_receipt="REC$(date +%Y)-$(shuf -i 1000-9999 -n 1 2>/dev/null || echo $RANDOM)"

    local temp_file="${FEES_FILE}.tmp.$$"
    awk -F',' -v r="$roll" -v np="$new_paid" -v nd="$new_due" -v st="$new_status" -v dt="$payment_date" -v rc="$new_receipt" '
        BEGIN { OFS = "," }
        NR == 1 { print $0; next }
        tolower($2) == tolower(r) {
            # Update receipt, paid, due, status, payment_date
            print rc, $2, $3, $4, np, nd, st, dt;
            next;
        }
        { print $0 }
    ' "$FEES_FILE" > "$temp_file"

    mv "$temp_file" "$FEES_FILE"
    echo "$new_receipt|$new_paid|$new_due|$new_status"
    return 0
}

# Fetch list of fee defaulters with pending dues
get_fee_defaulters() {
    if [ ! -f "$FEES_FILE" ] || [ ! -f "$STUDENTS_FILE" ]; then return 1; fi

    awk -F',' '
        # Pass 1: Student details
        NR == FNR {
            if (FNR > 1) {
                name[$1] = $2;
                phone[$1] = $4;
                dept[$1] = $8;
            }
            next;
        }
        # Pass 2: Fees records where status != PAID
        FNR > 1 {
            due = $6 + 0.0;
            if (due > 0.05) {
                roll = $2;
                n = (roll in name) ? name[roll] : "Unknown";
                p = (roll in phone) ? phone[roll] : "-";
                d = (roll in dept) ? dept[roll] : "-";
                printf "%s|%s|%s|%s|$%.2f|$%.2f|%s\n", roll, n, d, p, $4+0.0, due, $7;
            }
        }
    ' "$STUDENTS_FILE" "$FEES_FILE"
}

# Total Fee Collection Analytics
get_fee_analytics() {
    if [ ! -f "$FEES_FILE" ]; then
        echo "0.00|0.00|0.00|0"
        return
    fi

    awk -F',' '
        NR > 1 {
            total_expected += ($4 + 0.0);
            total_collected += ($5 + 0.0);
            total_due += ($6 + 0.0);
            if (($6 + 0.0) > 0.05) defaulters_count++;
        }
        END {
            printf "%.2f|%.2f|%.2f|%d\n", total_expected, total_collected, total_due, defaulters_count;
        }
    ' "$FEES_FILE"
}
