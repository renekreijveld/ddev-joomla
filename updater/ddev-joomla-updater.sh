#!/bin/bash

# ddev-joomla-updater - Update bash scripts to support Joomla running on DDEV
#
# Written by René Kreijveld - email@renekreijveld.nl
# This script is free software; you may redistribute it and/or modify it.
# This script comes without any warranty. Use it at your own risk, always backup your data and software before running this script.
#
# Version history
# 1.0 Initial version.
# 1.1 Code improvements and bug fixes

VERSION=1.0

# Folder where scripts are installed
SCRIPTS_DEST="/usr/local/bin"
CONFIG_DIR="${HOME}/.config/ddevjoomla"
LOGFILE="${CONFIG_DIR}/ddev-joomla-update.log"
CONFIG_FILE="${CONFIG_DIR}/config"

# Local scripts to install
LOCAL_SCRIPTS=( "addsite" "jdbdump" "jdbimp" "latestjoomla" "gosite" )

# GitHub Repo Base URL
GITHUB_BASE="https://raw.githubusercontent.com/renekreijveld/ddev-joomla/refs/heads/main"

# Create a temporary directory for downloads
TMPDIR=$(mktemp -d)
if [[ -z "${TMPDIR}" ]]; then
    echo "Error: failed to create temporary directory, exiting."
    exit 1
fi

# Track update results
UPDATED_SCRIPTS=()
FAILED_SCRIPTS=()
PASSWORD=""

cleanup() {
    rm -rf "${TMPDIR}"
}
trap "cleanup; echo 'Installation interrupted. Exiting...'; exit 1" SIGINT
trap cleanup EXIT

# Function to prompt for a value, with the option to keep the current one
prompt_for_input() {
    local current_value="$1"
    local prompt_message="$2"
    local new_value

    if [[ -n "$current_value" ]]; then
        read -p "$prompt_message [$current_value]: " new_value
        # If the user input is empty, keep the current value
        if [[ -z "$new_value" ]]; then
            new_value="$current_value"
        fi
    else
        read -p "$prompt_message: " new_value
    fi

    echo "$new_value"
}

start() {
    echo -e "Welcome to the DDEV support scripts for Joomla updater ${VERSION}.\n"
    echo -e "This updater and the software it installs come without any warranty. Use it at your own risk."
    echo -e "Always backup your data and software before running the updater and use the software it updates.\n"
    read -s -p "Input your password, this is needed for updating system files: " PASSWORD
    echo ""

    # Validate the password
    if [[ -z "${PASSWORD}" ]]; then
        echo "Error: password cannot be empty, exiting."
        exit 1
    fi

    if ! echo "${PASSWORD}" | sudo -S -v 2>/dev/null; then
        echo "Error: incorrect password, exiting."
        exit 1
    fi
}

# Load configuration file defaults
load_configfile() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        source "${CONFIG_FILE}"
    else
        echo "Error: configuration file ${CONFIG_FILE} not found, exiting."
        exit 1
    fi
}

# Check prerequisites before updating
check_prerequisites() {
    # Check if SCRIPTS_DEST directory exists and is writable
    if [[ ! -d "${SCRIPTS_DEST}" ]]; then
        echo "Error: scripts destination directory ${SCRIPTS_DEST} does not exist, exiting."
        exit 1
    fi

    # Initialize update log
    touch "${LOGFILE}" 2>/dev/null || {
        echo "Warning: could not create update log at ${LOGFILE}, continuing without logging."
        LOGFILE=""
    }
}

# Write a message to a logfile
log_message() {
    if [[ -n "${LOGFILE}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${LOGFILE}"
    fi
}

show_scripts_to_update() {
    echo -e "\nScripts that will be updated:"
    for script in "${LOCAL_SCRIPTS[@]}"; do
        echo "- ${script}"
    done
}

update_local_scripts() {
    echo -e "\n\nUpdating local scripts:"
    for script in "${LOCAL_SCRIPTS[@]}"; do
        echo -n "- updating ${script}... "

        # Download script from GitHub
        if ! curl -fsSL "${GITHUB_BASE}/src/Scripts/${script}" -o "${TMPDIR}/${script}"; then
            echo "FAILED (download error)"
            FAILED_SCRIPTS+=("${script}")
            log_message "FAILED to update ${script}: download error"
            continue
        fi

        # If a script already exists, backup it first
        if [[ -f "${SCRIPTS_DEST}/${script}" ]]; then
            BACKUP_FILE="${SCRIPTS_DEST}/${script}.$(date +%Y%m%d-%H%M%S)"
            if ! echo "${PASSWORD}" | sudo -S mv -f "${SCRIPTS_DEST}/${script}" "${BACKUP_FILE}" 2>/dev/null; then
                echo "FAILED (backup error)"
                FAILED_SCRIPTS+=("${script}")
                log_message "FAILED to update ${script}: backup error"
                continue
            fi
        fi

        # Move new script to destination
        if ! echo "${PASSWORD}" | sudo -S mv -f "${TMPDIR}/${script}" "${SCRIPTS_DEST}/${script}" 2>/dev/null; then
            echo "FAILED (move error)"
            FAILED_SCRIPTS+=("${script}")
            log_message "FAILED to update ${script}: move error"
            continue
        fi

        # Make script executable
        if ! echo "${PASSWORD}" | sudo -S chmod +x "${SCRIPTS_DEST}/${script}" 2>/dev/null; then
            echo "FAILED (chmod error)"
            FAILED_SCRIPTS+=("${script}")
            log_message "FAILED to update ${script}: chmod error"
            continue
        fi

        echo "OK"
        UPDATED_SCRIPTS+=("${script}")
        log_message "Successfully updated ${script}"
    done
}

the_end() {
    echo -e "\n################"
    echo "Update Summary:"
    echo "################"

    if [[ ${#UPDATED_SCRIPTS[@]} -gt 0 ]]; then
        echo -e "\nSuccessfully updated (${#UPDATED_SCRIPTS[@]}):"

        for script in "${UPDATED_SCRIPTS[@]}"; do
            echo "✓ ${script}"
            log_message "Successfully updated ${script}"
        done
    fi

    if [[ ${#FAILED_SCRIPTS[@]} -gt 0 ]]; then
        echo -e "\nFailed to update (${#FAILED_SCRIPTS[@]}):"
        for script in "${FAILED_SCRIPTS[@]}"; do
            echo "✗ ${script}"
            log_message "Failed to update ${script}"
        done
        echo -e "\nPlease check the update log for details: ${LOGFILE}\n"
        exit 1
    fi

    if [[ ${#UPDATED_SCRIPTS[@]} -eq 0 ]]; then
        echo -e "\nNo scripts were updated.\n"
            log_message "No scripts were updated"
        exit 1
    fi

    echo -e "\nUpdate completed successfully!"
    echo "All updated scripts have been backed up in ${SCRIPTS_DEST}/"
    echo "Backup files have timestamps appended to their names."
    echo -e "\nEnjoy your updated development setup!"

    if [[ -n "${LOGFILE}" ]]; then
        echo -e "\nUpdate log: ${LOGFILE}\n"
    fi
}

# Execute the script in order
log_message "Start ddev-joomla-updater ====================================="
start
load_configfile
check_prerequisites
show_scripts_to_update
read -r -p "Do you want to continue? [Y/n] " CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]?$ ]]; then
    echo "Update cancelled."
    exit 0
fi
update_local_scripts
the_end