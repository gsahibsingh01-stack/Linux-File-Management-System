#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Icons & Symbols Library
# ==============================================================================

ICON_APP="🎓"
ICON_STUDENT="👤"
ICON_ACADEMIC="📚"
ICON_ATTENDANCE="📅"
ICON_FEE="💳"
ICON_ANALYTICS="📊"
ICON_SETTINGS="⚙️"
ICON_BACKUP="💾"
ICON_SEARCH="🔍"
ICON_ADD="➕"
ICON_EDIT="✏️"
ICON_DELETE="🗑️"
ICON_SUCCESS="✅"
ICON_WARNING="⚠️"
ICON_DANGER="❌"
ICON_INFO="ℹ️"
ICON_STAR="⭐"
ICON_MEDAL="🥇"
ICON_LOCK="🔒"
ICON_KEY="🔑"
ICON_LOGOUT="🚪"
ICON_REPORT="📄"

# Text / ASCII Fallbacks if terminal doesn't render UTF-8 glyphs properly
get_status_badge() {
    local status="$1"
    local upper
    upper=$(echo "$status" | tr '[:lower:]' '[:upper:]')
    case "$upper" in
        ACTIVE)
            printf "${CLR_SUCCESS}${BOLD}[ ACTIVE ]${RESET}"
            ;;
        ON\ LEAVE|LEAVE)
            printf "${CLR_WARNING}${BOLD}[ ON LEAVE ]${RESET}"
            ;;
        GRADUATED)
            printf "${CLR_PRIMARY}${BOLD}[ GRADUATED ]${RESET}"
            ;;
        SUSPENDED)
            printf "${CLR_DANGER}${BOLD}[ SUSPENDED ]${RESET}"
            ;;
        PAID)
            printf "${CLR_SUCCESS}${BOLD}[ PAID ]${RESET}"
            ;;
        PARTIAL)
            printf "${CLR_WARNING}${BOLD}[ PARTIAL ]${RESET}"
            ;;
        DUE)
            printf "${CLR_DANGER}${BOLD}[ DUE ]${RESET}"
            ;;
        *)
            printf "${CLR_MUTED}[ %s ]${RESET}" "$status"
            ;;
    esac
}
