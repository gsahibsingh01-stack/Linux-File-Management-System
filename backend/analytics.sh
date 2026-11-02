#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Statistical & Analytics Service
# Powered by Linux Commands: awk, sort, cut, head, wc, printf
# ==============================================================================

DATA_DIR="${DATA_DIR:-data}"
STUDENTS_FILE="$DATA_DIR/students.csv"
ACADEMICS_FILE="$DATA_DIR/academics.csv"
ATTENDANCE_FILE="$DATA_DIR/attendance.csv"
FEES_FILE="$DATA_DIR/fees.csv"

# Source academics for CGPA calculation if needed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=backend/academics.sh
[ -f "$SCRIPT_DIR/academics.sh" ] && . "$SCRIPT_DIR/academics.sh"

# Calculate overall university academic KPIs
get_academic_kpis() {
    if [ ! -f "$STUDENTS_FILE" ] || [ ! -f "$ACADEMICS_FILE" ]; then
        echo "0|0.00"
        return
    fi

    # Compute overall batch average CGPA
    awk -F',' '
        NR == FNR {
            # Pass 1: Academics
            if (FNR > 1) {
                roll = $1;
                cr = $4 + 0;
                gp = $9 + 0;
                stud_credits[roll] += cr;
                stud_points[roll] += (cr * gp);
            }
            next;
        }
        # Pass 2: Students
        FNR > 1 {
            roll = $1;
            if (roll in stud_credits && stud_credits[roll] > 0) {
                cgpa = stud_points[roll] / stud_credits[roll];
                total_cgpa += cgpa;
                graded_students++;
            }
        }
        END {
            avg_cgpa = (graded_students > 0) ? (total_cgpa / graded_students) : 0;
            printf "%d|%.2f\n", graded_students, avg_cgpa;
        }
    ' "$ACADEMICS_FILE" "$STUDENTS_FILE"
}

# Top Performers / Dean's Honor Roll (Ranked by CGPA)
# Output lines: rank|roll_no|name|department|cgpa|standing
get_top_students() {
    local limit="${1:-5}"

    if [ ! -f "$STUDENTS_FILE" ] || [ ! -f "$ACADEMICS_FILE" ]; then return 1; fi

    # Compute student CGPAs, format, sort, and rank
    awk -F',' '
        # Pass 1: Student info
        NR == FNR {
            if (FNR > 1) {
                name[$1] = $2;
                dept[$1] = $8;
                status[$1] = $11;
            }
            next;
        }
        # Pass 2: Academics
        FNR > 1 {
            roll = $1;
            cr = $4 + 0;
            gp = $9 + 0;
            stud_credits[roll] += cr;
            stud_points[roll] += (cr * gp);
        }
        END {
            for (roll in name) {
                if (roll in stud_credits && stud_credits[roll] > 0) {
                    cgpa = stud_points[roll] / stud_credits[roll];
                    printf "%.2f|%s|%s|%s\n", cgpa, roll, name[roll], dept[roll];
                }
            }
        }
    ' "$STUDENTS_FILE" "$ACADEMICS_FILE" | sort -t'|' -k1 -nr | head -n "$limit" | awk -F'|' '
        {
            rank = NR;
            cgpa = $1;
            roll = $2;
            name = $3;
            dept = $4;
            printf "%d|%s|%s|%s|%.2f\n", rank, roll, name, dept, cgpa;
        }
    '
}

# Department-wise distribution
# Output lines: Department|Count|Percentage
get_department_distribution() {
    if [ ! -f "$STUDENTS_FILE" ]; then return 1; fi

    awk -F',' '
        NR > 1 && $8 != "" {
            dept_counts[$8]++;
            total++;
        }
        END {
            for (d in dept_counts) {
                pct = (total > 0) ? (dept_counts[d] / total) * 100 : 0;
                printf "%s|%d|%.1f\n", d, dept_counts[d], pct;
            }
        }
    ' "$STUDENTS_FILE" | sort -t'|' -k2 -nr
}

# Gender ratio breakdown
get_gender_distribution() {
    if [ ! -f "$STUDENTS_FILE" ]; then return 1; fi

    awk -F',' '
        NR > 1 {
            g = toupper($6);
            if (g ~ /^M/) m++;
            else if (g ~ /^F/) f++;
            else o++;
            total++;
        }
        END {
            printf "Male|%d|%.1f\nFemale|%d|%.1f\nOther|%d|%.1f\n", 
                m, (total>0 ? m/total*100 : 0),
                f, (total>0 ? f/total*100 : 0),
                o, (total>0 ? o/total*100 : 0);
        }
    ' "$STUDENTS_FILE"
}
