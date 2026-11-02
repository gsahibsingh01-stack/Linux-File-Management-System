#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Input Validators
# ==============================================================================

# Validate Roll Number (Alphanumeric, 4 to 15 characters, no commas or colons)
validate_roll_no() {
    local val="$1"
    if [[ "$val" =~ ^[A-Za-z0-9_-]{4,15}$ ]]; then
        return 0
    fi
    return 1
}

# Validate Person Name (Alphabets, spaces, dots, 2 to 50 characters)
validate_name() {
    local val="$1"
    if [[ "$val" =~ ^[A-Za-z\ .\'-]{2,50}$ ]]; then
        return 0
    fi
    return 1
}

# Validate Email Address
validate_email() {
    local val="$1"
    if [[ "$val" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    fi
    return 1
}

# Validate Phone Number (10 to 15 digits, optional + or -)
validate_phone() {
    local val="$1"
    if [[ "$val" =~ ^\+?[0-9\ -]{10,16}$ ]]; then
        return 0
    fi
    return 1
}

# Validate Date (YYYY-MM-DD)
validate_date() {
    local val="$1"
    if [[ "$val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        local yyyy mm dd
        yyyy=$(echo "$val" | cut -d'-' -f1)
        mm=$(echo "$val" | cut -d'-' -f2)
        dd=$(echo "$val" | cut -d'-' -f3)

        # Remove leading zeros for comparison
        mm=$((10#$mm))
        dd=$((10#$dd))
        yyyy=$((10#$yyyy))

        if [ "$mm" -ge 1 ] && [ "$mm" -le 12 ] && [ "$dd" -ge 1 ] && [ "$dd" -le 31 ] && [ "$yyyy" -ge 1950 ] && [ "$yyyy" -le 2035 ]; then
            return 0
        fi
    fi
    return 1
}

# Validate Semester (1 to 8)
validate_semester() {
    local val="$1"
    if [[ "$val" =~ ^[1-8]$ ]]; then
        return 0
    fi
    return 1
}

# Validate Marks (0 to 100, integer or decimal)
validate_marks() {
    local val="$1"
    if [[ "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        local int_val
        int_val=$(printf "%.0f" "$val" 2>/dev/null || echo 0)
        if [ "$int_val" -ge 0 ] && [ "$int_val" -le 100 ]; then
            return 0
        fi
    fi
    return 1
}

# Validate Fee Amount (Non-negative numeric)
validate_amount() {
    local val="$1"
    if [[ "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        return 0
    fi
    return 1
}

# Validate Gender
validate_gender() {
    local val
    val=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case "$val" in
        M|MALE|F|FEMALE|O|OTHER) return 0 ;;
        *) return 1 ;;
    esac
}

# Validate Blood Group
validate_blood_group() {
    local val
    val=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case "$val" in
        A+|A-|B+|B-|AB+|AB-|O+|O-) return 0 ;;
        *) return 1 ;;
    esac
}

# Validate Status
validate_status() {
    local val
    val=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case "$val" in
        ACTIVE|ON\ LEAVE|GRADUATED|SUSPENDED) return 0 ;;
        *) return 1 ;;
    esac
}
