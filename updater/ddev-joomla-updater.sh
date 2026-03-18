#!/bin/bash

# ddev-joomla-updatger - Update bash scripts to support Joomla running on DDEV
#
# Written by René Kreijveld - email@renekreijveld.nl
# This script is free software; you may redistribute it and/or modify it.
# This script comes without any warranty. Use it at your own risk, always backup your data and software before running this script.
#
# Version history
# 1.0 Initial version.

VERSION=1.0

# Folder where scripts are installed
SCRIPTS_DEST="/usr/local/bin"
CONFIG_DIR="${HOME}/.config/ddevjoomla"
INSTALL_LOG="${CONFIG_DIR}/ddev-joomla-install.log"
CONFIG_FILE="${CONFIG_DIR}/config"

# Local scripts to install
LOCAL_SCRIPTS=( "addsite" "jdbdump" "jdbimp" "latestjoomla" )

# GitHub Repo Base URL
GITHUB_BASE="https://raw.githubusercontent.com/renekreijveld/ddev-joomla/refs/heads/main"

# Create a temporary directory for downloads
TMPDIR=$(mktemp -d)

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
    echo -e "Welcome to the DDEV support scripts for Joomla updater ${THISVERSION}.\n"
    echo -e "This updater and the software it installs come without any warranty. Use it at your own risk.\nAlways backup your data and software before running the installer and use the software it installs.\n"
    read -s -p "Input your password, this is needed for updating system files: " PASSWORD

    # Validate the password
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

update_local_scripts() {
    echo -e "\n\nUpdate local scripts:"
    for script in "${LOCAL_SCRIPTS[@]}"; do
        echo "- update ${script}."
        if ! curl -fsSL "${GITHUB_BASE}/src/Scripts/${script}" -o "${TMPDIR}/${script}"; then
            echo "  Warning: failed to download ${script}, skipping."
            continue
        fi

        # If a script already exists, backup it first
        if [ -f "${SCRIPTS_DEST}/${script}" ]; then
            echo "${PASSWORD}" | sudo -S mv -f "${SCRIPTS_DEST}/${script}" "${SCRIPTS_DEST}/${script}.$(date +%Y%m%d-%H%M%S)"
        fi

        echo "${PASSWORD}" | sudo -S mv -f "${TMPDIR}/${script}" "${SCRIPTS_DEST}/${script}" > /dev/null
        echo "${PASSWORD}" | sudo -S chmod +x "${SCRIPTS_DEST}/${script}"
    done
    echo "For each installed script a backup was made. Check the folder ${SCRIPTS_DEST}."
}

the_end() {
    echo -e "\nUpdate completed, enjoy your development setup!"
}

# Execute the script in order
start
load_configfile
update_local_scripts
the_end