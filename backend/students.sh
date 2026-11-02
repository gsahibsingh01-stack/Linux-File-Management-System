#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Student Operations Service
# Powered by Linux Commands: awk, sed, grep, cut, sort, wc, date
# ==============================================================================

DATA_DIR="${DATA_DIR:-data}"
STUDENTS_FILE="$DATA_DIR/students.csv"
ATTENDANCE_FILE="$DATA_DIR/attendance.csv"
FEES_FILE="$DATA_DIR/fees.csv"
ACADEMICS_FILE="$DATA_DIR/academics.csv"
ARCHIVE_FILE="$DATA_DIR/archive.csv"

# Count total active students
get_student_count() {
    if [ ! -f "$STUDENTS_FILE" ]; then
        echo 0
        return
    fi
    local count
    count=$(tail -n +2 "$STUDENTS_FILE" | grep -v '^[[:space:]]*$' | wc -l)
    echo "${count//[[:space:]]/}"
}

# Fetch all student records (skipping header)
get_all_students() {
    if [ ! -f "$STUDENTS_FILE" ]; then return 1; fi
    tail -n +2 "$STUDENTS_FILE" | grep -v '^[[:space:]]*$'
}

# Get single student by Roll Number
get_student_by_roll() {
    local roll="$1"
    if [ ! -f "$STUDENTS_FILE" ]; then return 1; fi
    awk -F',' -v r="$roll" '
        NR > 1 && tolower($1) == tolower(r) {
            print $0;
            exit;
        }
    ' "$STUDENTS_FILE"
}

# Check if roll number exists
roll_number_exists() {
    local roll="$1"
    local res
    res=$(get_student_by_roll "$roll")
    [ -n "$res" ]
}

# Search students across all text fields (Case-Insensitive)
search_students() {
    local query="$1"
    if [ ! -f "$STUDENTS_FILE" ]; then return 1; fi
    awk -F',' -v q="$query" '
        BEGIN { q = tolower(q) }
        NR > 1 {
            match_found = 0;
            for (i=1; i<=NF; i++) {
                if (index(tolower($i), q) > 0) {
                    match_found = 1;
                    break;
                }
            }
            if (match_found) print $0;
        }
    ' "$STUDENTS_FILE"
}

# Filter students by Department, Semester, or Status
filter_students() {
    local target_dept="$1"
    local target_sem="$2"
    local target_status="$3"

    awk -F',' -v d="$target_dept" -v s="$target_sem" -v st="$target_status" '
        NR > 1 {
            d_ok = (d == "" || tolower($8) == tolower(d));
            s_ok = (s == "" || $9 == s);
            st_ok = (st == "" || tolower($11) == tolower(st));
            if (d_ok && s_ok && st_ok) print $0;
        }
    ' "$STUDENTS_FILE"
}

# Add a new student record atomically
add_student() {
    local roll="$1"
    local name="$2"
    local email="$3"
    local phone="$4"
    local dob="$5"
    local gender="$6"
    local blood="$7"
    local dept="$8"
    local sem="$9"
    local enroll_date="${10:-$(date +%Y-%m-%d)}"
    local status="${11:-ACTIVE}"

    if roll_number_exists "$roll"; then
        echo "ERROR: Student with Roll Number '$roll' already exists." >&2
        return 1
    fi

    # Escape any unintended commas in text fields
    name="${name//,/ }"
    dept="${dept//,/ }"

    # Append to students.csv
    echo "${roll},${name},${email},${phone},${dob},${gender},${blood},${dept},${sem},${enroll_date},${status}" >> "$STUDENTS_FILE"

    # Initialize default attendance record if not present
    if [ -f "$ATTENDANCE_FILE" ]; then
        if ! grep -qi "^${roll}," "$ATTENDANCE_FILE"; then
            echo "${roll},60,60,100.0,${enroll_date}" >> "$ATTENDANCE_FILE"
        fi
    fi

    # Initialize default fee record if not present
    if [ -f "$FEES_FILE" ]; then
        if ! grep -qi ",${roll}," "$FEES_FILE"; then
            local rec_no="REC$(date +%Y)-$(shuf -i 1000-9999 -n 1 2>/dev/null || echo $RANDOM)"
            echo "${rec_no},${roll},Standard Semester Fee,4500.00,0.00,4500.00,DUE,N/A" >> "$FEES_FILE"
        fi
    fi

    return 0
}

# Update student record atomically using temporary file
update_student() {
    local roll="$1"
    local name="$2"
    local email="$3"
    local phone="$4"
    local dob="$5"
    local gender="$6"
    local blood="$7"
    local dept="$8"
    local sem="$9"
    local status="${10}"

    if ! roll_number_exists "$roll"; then
        echo "ERROR: Student with Roll Number '$roll' does not exist." >&2
        return 1
    fi

    local temp_file
    temp_file="${STUDENTS_FILE}.tmp.$$"

    awk -F',' -v r="$roll" \
               -v n="$name" \
               -v e="$email" \
               -v p="$phone" \
               -v d="$dob" \
               -v g="$gender" \
               -v b="$blood" \
               -v dp="$dept" \
               -v s="$sem" \
               -v st="$status" '
        BEGIN { OFS = "," }
        NR == 1 { print $0; next }
        tolower($1) == tolower(r) {
            # Update fields while keeping roll_no ($1) and enrollment_date ($10) intact
            if (n != "") $2 = n;
            if (e != "") $3 = e;
            if (p != "") $4 = p;
            if (d != "") $5 = d;
            if (g != "") $6 = g;
            if (b != "") $7 = b;
            if (dp != "") $8 = dp;
            if (s != "") $9 = s;
            if (st != "") $11 = st;
            print $0;
        }
        tolower($1) != tolower(r) {
            print $0;
        }
    ' "$STUDENTS_FILE" > "$temp_file"

    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$STUDENTS_FILE"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Delete student record and archive to archive.csv
delete_student() {
    local roll="$1"
    local reason="${2:-Administrative Removal}"

    local student_row
    student_row=$(get_student_by_roll "$roll")
    if [ -z "$student_row" ]; then
        echo "ERROR: Student '$roll' not found." >&2
        return 1
    fi

    local name dept sem arch_date
    name=$(echo "$student_row" | cut -d',' -f2)
    dept=$(echo "$student_row" | cut -d',' -f8)
    sem=$(echo "$student_row" | cut -d',' -f9)
    arch_date=$(date +%Y-%m-%d)

    # Archive record
    echo "${roll},${name},${dept},${sem},${arch_date},${reason}" >> "$ARCHIVE_FILE"

    # Remove from students.csv
    local temp_stu="${STUDENTS_FILE}.tmp.$$"
    awk -F',' -v r="$roll" 'NR == 1 || tolower($1) != tolower(r)' "$STUDENTS_FILE" > "$temp_stu"
    mv "$temp_stu" "$STUDENTS_FILE"

    return 0
}
