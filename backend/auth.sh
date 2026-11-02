#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Authentication & Session Service
# Powered by Linux Commands: awk, grep, cut, sha256sum, date
# ==============================================================================

DATA_DIR="${DATA_DIR:-data}"
USERS_FILE="$DATA_DIR/users.csv"
SESSION_FILE="/tmp/apex_session_$(whoami 2>/dev/null || echo user).tmp"

# Compute SHA-256 hash of password
hash_password() {
    local pass="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        echo -n "$pass" | sha256sum | cut -d' ' -f1
    elif command -v md5sum >/dev/null 2>&1; then
        echo -n "$pass" | md5sum | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        echo -n "$pass" | shasum -a 256 | cut -d' ' -f1
    else
        # Fallback checksum
        echo -n "$pass" | cksum | cut -d' ' -f1
    fi
}

# Authenticate user credentials
# Returns 0 on success, 1 on failure
authenticate_user() {
    local username="$1"
    local password="$2"

    if [ ! -f "$USERS_FILE" ]; then
        return 1
    fi

    local hashed_pass
    hashed_pass=$(hash_password "$password")

    # Match username and hash using awk
    local user_record
    user_record=$(awk -F',' -v u="$username" -v p="$hashed_pass" '
        $1 == u && $2 == p && $6 == "ACTIVE" {
            print $1 "|" $3 "|" $4 "|" $5
            exit
        }
    ' "$USERS_FILE")

    if [ -n "$user_record" ]; then
        # Save active session
        local ts
        ts=$(date "+%Y-%m-%d %H:%M:%S")
        echo "${user_record}|${ts}" > "$SESSION_FILE"
        return 0
    else
        return 1
    fi
}

# Get current session info
get_current_user() {
    if [ -f "$SESSION_FILE" ]; then
        cat "$SESSION_FILE"
    else
        echo ""
    fi
}

get_current_username() {
    get_current_user | cut -d'|' -f1
}

get_current_name() {
    get_current_user | cut -d'|' -f2
}

get_current_role() {
    local role
    role=$(get_current_user | cut -d'|' -f3)
    echo "${role:-guest}"
}

# Permission Checks
is_admin() {
    [ "$(get_current_role)" = "admin" ]
}

is_faculty() {
    local r
    r=$(get_current_role)
    [ "$r" = "admin" ] || [ "$r" = "faculty" ]
}

can_modify() {
    is_faculty
}

# Logout user
logout_user() {
    rm -f "$SESSION_FILE"
}
