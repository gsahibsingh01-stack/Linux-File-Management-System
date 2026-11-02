#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Backup & Reporting Service
# Powered by Linux Commands: tar, gzip, find, date, ls, cat, awk
# ==============================================================================

BACKUP_DIR="${BACKUP_DIR:-backups}"
EXPORTS_DIR="${EXPORTS_DIR:-exports}"
DATA_DIR="${DATA_DIR:-data}"

mkdir -p "$BACKUP_DIR" "$EXPORTS_DIR"

# Create a compressed tar.gz backup
create_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/apex_student_backup_${timestamp}.tar.gz"

    if [ ! -d "$DATA_DIR" ]; then
        echo "ERROR: Data directory '$DATA_DIR' does not exist." >&2
        return 1
    fi

    # Create tar archive
    tar -czf "$backup_file" "$DATA_DIR" 2>/dev/null
    if [ $? -eq 0 ] && [ -f "$backup_file" ]; then
        local size
        size=$(du -h "$backup_file" 2>/dev/null | cut -f1 || echo "OK")
        echo "$backup_file|$size|$timestamp"
        return 0
    else
        echo "ERROR: Failed to create backup archive." >&2
        return 1
    fi
}

# List available backups
list_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then return; fi
    find "$BACKUP_DIR" -type f -name "*.tar.gz" 2>/dev/null | sort -r
}

# Restore database from backup
restore_backup() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        echo "ERROR: Backup file '$backup_file' not found." >&2
        return 1
    fi

    # Extract archive over data directory
    tar -xzf "$backup_file" 2>/dev/null
    if [ $? -eq 0 ]; then
        return 0
    else
        echo "ERROR: Failed extracting backup archive." >&2
        return 1
    fi
}

# Generate a master printable text or markdown report
generate_master_report() {
    local format="${1:-txt}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="$EXPORTS_DIR/university_master_report_${timestamp}.${format}"

    {
        echo "================================================================================"
        echo "                APEX UNIVERSITY - STUDENT RECORD MANAGEMENT REPORT              "
        echo "                      Generated: $(date '+%A, %B %d, %Y %H:%M:%S')              "
        echo "================================================================================"
        echo ""
        echo "1. ENROLLED STUDENTS REGISTRY:"
        echo "--------------------------------------------------------------------------------"
        printf "%-12s | %-20s | %-22s | %-4s | %-10s\n" "Roll No" "Full Name" "Department" "Sem" "Status"
        echo "--------------------------------------------------------------------------------"
        if [ -f "$DATA_DIR/students.csv" ]; then
            awk -F',' 'NR > 1 { printf "%-12s | %-20s | %-22s | %-4s | %-10s\n", $1, substr($2,1,20), substr($8,1,22), $9, $11 }' "$DATA_DIR/students.csv"
        fi
        echo ""
        echo "2. ATTENDANCE & ACADEMIC AUDIT:"
        echo "--------------------------------------------------------------------------------"
        printf "%-12s | %-12s | %-12s | %-12s\n" "Roll No" "Total Class" "Attended" "Percentage"
        echo "--------------------------------------------------------------------------------"
        if [ -f "$DATA_DIR/attendance.csv" ]; then
            awk -F',' 'NR > 1 { printf "%-12s | %-12s | %-12s | %-12s%%\n", $1, $2, $3, $4 }' "$DATA_DIR/attendance.csv"
        fi
        echo ""
        echo "3. FINANCIAL LEDGER & FEE DUES:"
        echo "--------------------------------------------------------------------------------"
        printf "%-12s | %-14s | %-10s | %-10s | %-10s\n" "Receipt" "Roll No" "Total" "Paid" "Status"
        echo "--------------------------------------------------------------------------------"
        if [ -f "$DATA_DIR/fees.csv" ]; then
            awk -F',' 'NR > 1 { printf "%-12s | %-14s | $%-9.2f | $%-9.2f | %-10s\n", $1, $2, $4+0, $5+0, $7 }' "$DATA_DIR/fees.csv"
        fi
        echo ""
        echo "================================================================================"
        echo "                             END OF OFFICIAL REPORT                             "
        echo "================================================================================"
    } > "$report_file"

    echo "$report_file"
}
