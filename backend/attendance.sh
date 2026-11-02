#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Attendance Service
# Powered by Linux Commands: awk, grep, date, cut
# ==============================================================================

DATA_DIR="${DATA_DIR:-data}"
ATTENDANCE_FILE="$DATA_DIR/attendance.csv"
STUDENTS_FILE="$DATA_DIR/students.csv"

# Get student attendance record
# Output: roll_no,total_classes,attended_classes,attendance_percentage,last_updated
get_attendance_record() {
    local roll="$1"
    if [ ! -f "$ATTENDANCE_FILE" ]; then return 1; fi

    awk -F',' -v r="$roll" '
        NR > 1 && tolower($1) == tolower(r) {
            print $0;
            exit;
        }
    ' "$ATTENDANCE_FILE"
}

# Update student attendance
update_attendance() {
    local roll="$1"
    local total="$2"
    local attended="$3"
    local date_now
    date_now=$(date +%Y-%m-%d)

    if [ "$total" -le 0 ]; then
        echo "ERROR: Total classes must be greater than 0." >&2
        return 1
    fi
    if [ "$attended" -gt "$total" ]; then
        echo "ERROR: Attended classes cannot exceed total classes." >&2
        return 1
    fi

    # Calculate percentage with awk
    local pct
    pct=$(awk -v a="$attended" -v t="$total" 'BEGIN { printf "%.1f", (a / t) * 100 }')

    local temp_file="${ATTENDANCE_FILE}.tmp.$$"
    awk -F',' -v r="$roll" -v t="$total" -v a="$attended" -v p="$pct" -v d="$date_now" '
        BEGIN { OFS = ","; found = 0 }
        NR == 1 { print $0; next }
        tolower($1) == tolower(r) {
            print r, t, a, p, d;
            found = 1;
            next;
        }
        { print $0 }
        END {
            if (found == 0) {
                print r, t, a, p, d;
            }
        }
    ' "$ATTENDANCE_FILE" > "$temp_file"

    mv "$temp_file" "$ATTENDANCE_FILE"
    return 0
}

# Retrieve all students with attendance below threshold (default 75%)
# Merges student name and department
get_attendance_shortage() {
    local threshold="${1:-75.0}"
    if [ ! -f "$ATTENDANCE_FILE" ] || [ ! -f "$STUDENTS_FILE" ]; then return 1; fi

    # Use awk to join students.csv and attendance.csv
    awk -F',' -v th="$threshold" '
        # Pass 1: Load student names and departments
        NR == FNR {
            if (FNR > 1) {
                name[$1] = $2;
                dept[$1] = $8;
                sem[$1] = $9;
            }
            next;
        }
        # Pass 2: Filter attendance records below threshold
        FNR > 1 {
            pct = $4 + 0.0;
            if (pct < th + 0.0) {
                roll = $1;
                n = (roll in name) ? name[roll] : "Unknown";
                d = (roll in dept) ? dept[roll] : "Unknown";
                s = (roll in sem) ? sem[roll] : "-";
                printf "%s|%s|%s|%s|%s|%s|%.1f%%\n", roll, n, d, s, $2, $3, pct;
            }
        }
    ' "$STUDENTS_FILE" "$ATTENDANCE_FILE"
}

# Overall Attendance Statistics
get_attendance_summary() {
    if [ ! -f "$ATTENDANCE_FILE" ]; then
        echo "0.0|0"
        return
    fi

    awk -F',' '
        NR > 1 {
            total_students++;
            sum_pct += ($4 + 0.0);
            if (($4 + 0.0) < 75.0) shortage_count++;
        }
        END {
            avg = (total_students > 0) ? (sum_pct / total_students) : 0;
            printf "%.1f|%d\n", avg, shortage_count;
        }
    ' "$ATTENDANCE_FILE"
}
