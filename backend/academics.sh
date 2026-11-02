#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Academic & GPA/CGPA Service
# Powered by Linux Commands: awk, grep, bc, cut, printf
# ==============================================================================

DATA_DIR="${DATA_DIR:-data}"
ACADEMICS_FILE="$DATA_DIR/academics.csv"

# Determine letter grade and grade point from marks (0-100)
# Outputs: GRADE|GRADE_POINT
get_grade_and_point() {
    local marks="$1"
    awk -v m="$marks" 'BEGIN {
        if (m >= 90)      print "O|10.0";
        else if (m >= 80) print "A+|9.0";
        else if (m >= 70) print "A|8.0";
        else if (m >= 60) print "B+|7.0";
        else if (m >= 50) print "B|6.0";
        else if (m >= 40) print "P|5.0";
        else              print "F|0.0";
    }'
}

# Fetch all course records for a student
get_student_courses() {
    local roll="$1"
    local sem="$2"
    if [ ! -f "$ACADEMICS_FILE" ]; then return 1; fi

    awk -F',' -v r="$roll" -v s="$sem" '
        NR > 1 && tolower($1) == tolower(r) && (s == "" || $10 == s) {
            print $0
        }
    ' "$ACADEMICS_FILE"
}

# Add or update course grade entry for student
add_course_mark() {
    local roll="$1"
    local course_code="$2"
    local course_name="$3"
    local credits="$4"
    local internal="$5"
    local external="$6"
    local sem="$7"

    # Total marks
    local total
    total=$(awk -v i="$internal" -v e="$external" 'BEGIN { printf "%.1f", i + e }')

    local grade_info grade grade_point
    grade_info=$(get_grade_and_point "$total")
    grade=$(echo "$grade_info" | cut -d'|' -f1)
    grade_point=$(echo "$grade_info" | cut -d'|' -f2)

    # Sanitize names
    course_name="${course_name//,/ }"

    # Check if this course for this student and semester already exists
    local temp_file="${ACADEMICS_FILE}.tmp.$$"
    local updated=0

    if [ -f "$ACADEMICS_FILE" ]; then
        awk -F',' -v r="$roll" -v c="$course_code" -v s="$sem" \
                  -v cn="$course_name" -v cr="$credits" -v im="$internal" \
                  -v em="$external" -v tm="$total" -v g="$grade" -v gp="$grade_point" '
            BEGIN { OFS = ","; found = 0 }
            NR == 1 { print $0; next }
            tolower($1) == tolower(r) && tolower($2) == tolower(c) && $10 == s {
                print r, c, cn, cr, im, em, tm, g, gp, s;
                found = 1;
                next;
            }
            { print $0 }
            END {
                if (found == 0) {
                    print r, c, cn, cr, im, em, tm, g, gp, s;
                }
            }
        ' "$ACADEMICS_FILE" > "$temp_file"

        mv "$temp_file" "$ACADEMICS_FILE"
    else
        echo "roll_no,course_code,course_name,credits,internal_marks,external_marks,total_marks,grade,grade_point,semester" > "$ACADEMICS_FILE"
        echo "${roll},${course_code},${course_name},${credits},${internal},${external},${total},${grade},${grade_point},${sem}" >> "$ACADEMICS_FILE"
    fi

    return 0
}

# Calculate GPA for a specific semester
calculate_gpa() {
    local roll="$1"
    local sem="$2"
    if [ ! -f "$ACADEMICS_FILE" ]; then
        echo "0.00"
        return
    fi

    awk -F',' -v r="$roll" -v s="$sem" '
        NR > 1 && tolower($1) == tolower(r) && ($10 == s || s == "") {
            credits = $4 + 0;
            gp = $9 + 0;
            total_credits += credits;
            total_points += (credits * gp);
        }
        END {
            if (total_credits > 0) {
                printf "%.2f\n", (total_points / total_credits);
            } else {
                print "0.00";
            }
        }
    ' "$ACADEMICS_FILE"
}

# Calculate Cumulative CGPA across all semesters
calculate_cgpa() {
    local roll="$1"
    calculate_gpa "$roll" ""
}

# Academic Standing Description
get_academic_standing() {
    local cgpa="$1"
    awk -v c="$cgpa" 'BEGIN {
        if (c >= 9.0)      print "First Class with Distinction (Honors / Dean List)";
        else if (c >= 8.0) print "First Class with Distinction";
        else if (c >= 6.5) print "First Class";
        else if (c >= 5.0) print "Second Class";
        else if (c > 0.0)  print "Academic Warning (Attendance / Remedial Required)";
        else               print "No Grades Recorded Yet";
    }'
}
