#!/usr/bin/env bash
# ==============================================================================
# Apex Student Record Management System - Master Application Entry Point
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DATA_DIR="$ROOT_DIR/data"
export BACKUP_DIR="$ROOT_DIR/backups"
export EXPORTS_DIR="$ROOT_DIR/exports"

# Create directories if not existing
mkdir -p "$DATA_DIR" "$BACKUP_DIR" "$EXPORTS_DIR"

# Source UI components and Auth
. "$ROOT_DIR/dependencies/colors.sh"
. "$ROOT_DIR/dependencies/boxes.sh"
. "$ROOT_DIR/dependencies/icons.sh"
. "$ROOT_DIR/backend/auth.sh"
. "$ROOT_DIR/frontend/ui_components.sh"
. "$ROOT_DIR/frontend/ui_auth.sh"
. "$ROOT_DIR/frontend/ui_menu.sh"

# Trap Ctrl+C for clean exit
trap 'printf "\n\n${CLR_MUTED}Session terminated by user.${RESET}\n\n"; logout_user; exit 0' INT TERM

# Start with Authentication Screen
show_login_screen

# On successful login, proceed to Main Application Menu
run_main_menu
