#!/bin/bash

# ddev-joomla-installer.sh - Install bash scripts to support Joomla running on DDEV
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
LOGFILE="${CONFIG_DIR}/ddev-joomla-install.log"
CONFIG_FILE="${CONFIG_DIR}/config"

# Local scripts to install
LOCAL_SCRIPTS=( "jaddsite" "jdbdump" "jdbimp" "jddev" "jlatest" "gosite" )

# GitHub Repo Base URL
GITHUB_BASE="https://raw.githubusercontent.com/renekreijveld/ddev-joomla/refs/heads/main"

# Logged-in User
USERNAME=$(whoami)

EXISTING_PATHS=()

# Cleanup sudo session on interrupt
trap "echo 'Installation interrupted. Exiting...'; sudo -k 2>/dev/null; exit 1" SIGINT

# Cleanup sudo session on normal exit
trap "sudo -k 2>/dev/null" EXIT

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

# Write a message to a logfile
log_message() {
    if [[ -n "${LOGFILE}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${LOGFILE}"
    fi
}

create_config() {
    # Create config directory if it doesn't exist
    mkdir -p "${CONFIG_DIR}"
    # Create logfile
    touch "${LOGFILE}"
    # Log start if installation
    log_message "Start ddev-joomla-installer ====================================="
}

start() {
    clear
    echo -e "Welcome to the DDEV support scripts for Joomla installer ${VERSION}.\n"
    echo -e "PLEASE READ EVERYTHING CAREFULLY BEFORE CONTINUING!\n"
    echo "Installation output will be logged in the file ${LOGFILE}."
    echo -e "Check this file if you encounter any issues during installation.\n"
    echo -e "This installer and the software it installs come without any warranty. Use it at your own risk.\nAlways backup your data and software before running the installer.\n"
    read -p "Press Enter to continue, or press Ctrl-C to abort. "
}

# Function to check if a script is already installed
is_installed() {
    [ -f "${SCRIPTS_DEST}/$1" ]
}

prechecks() {
    log_message "Running prechecks"
    clear
    echo "The installer will first check if the scripts are already installed."

    INSTALLED_SCRIPTS=()
    for script in "${LOCAL_SCRIPTS[@]}"; do
        if is_installed "${script}"; then
            INSTALLED_SCRIPTS+=("${script}")
        fi
    done

    if [ ${#INSTALLED_SCRIPTS[@]} -gt 0 ]; then
        echo -e "\nThe following scripts are already installed at ${SCRIPTS_DEST}:\n"
        log_message "The following scripts are already installed at ${SCRIPTS_DEST}:"
        for script in "${INSTALLED_SCRIPTS[@]}"; do
            echo "- ${script}"
            log_message "- ${script}"
        done
        echo -e "\nThe installer will create backups of these scripts.\n"
        read -p "Press Enter to start the installation, or press Ctrl-C to abort. "
    else
        echo "None of the scripts were already installed. Proceeding."
        log_message "No previous installed scripts found"
    fi
}

ask_defaults() {
    log_message "Running ask_defaults"
    clear
    # Check if config file already exists and if so, backup it
    if [[ -f "${CONFIG_FILE}" ]]; then
        # Backup existing config file
        echo "The config file ${CONFIG_FILE} already exists, a backup will be created."
        log_message "The config file ${CONFIG_FILE} already exists"
        BACKUPFILE="${CONFIG_FILE}.$(date +%Y%m%d-%H%M%S)"
        cp "${CONFIG_FILE}" "${BACKUPFILE}"
        echo "Existing config file backupped to ${BACKUPFILE}."
        log_message "Existing config file backupped to ${BACKUPFILE}"
    fi

    log_message "${CONFIG_DIR} created"
    echo -e "\nBefore the installation starts, some default values need to be set."
    echo "These values will be used during installation and will be saved in a config file."
    echo "Some of the scripts depend on this config file and will not work without it."
    echo -e "\nThe location of the config file is ${CONFIG_FILE}.\n"
    echo -e "If a default proposed value is correct, just press Enter.\n"
    rootfolder=$(prompt_for_input "$HOME/Development/sites" "Directory path where your websites will be stored:")
    backupfolder=$(prompt_for_input "$HOME/Development/backup" "Directory path where your backups will be stored:")

    # Validate webserver input
    while true; do
        webserver=$(prompt_for_input "nginx" "Default webserver for projects (nginx or apache):")
        if [[ "$webserver" == "nginx" || "$webserver" == "apache" ]]; then
            break
        else
            echo "Error: Please enter either 'nginx' or 'apache'."
        fi
    done

    echo -e "You will now be asked for your password, which is needed for the installation of the scripts."
    echo -e "Your password will not be stored in a file, it is only used for the installation.\n"
    read -s -p "Your password: " PASSWORD

    # Validate the password
    if ! echo "${PASSWORD}" | sudo -S -v 2>/dev/null; then
        echo "Error: incorrect password, exiting."
        log_message "User entered incorrect password, exiting"
        exit 1
    fi

    # Write the values to the config file
    NOW=$(date +"%Y-%m-%d %H:%M:%S")
    echo "# Configuration file for php development environment" > "${CONFIG_FILE}"
    echo "# Generated at ${NOW}" >> "${CONFIG_FILE}"
    echo "ROOTFOLDER=${rootfolder}" >> "${CONFIG_FILE}"
    echo "BACKUPFOLDER=${backupfolder}" >> "${CONFIG_FILE}"
    echo "WEBSERVER=${webserver}" >> "${CONFIG_FILE}"
    echo "INSTALLER_VERSION=${VERSION}" >> "${CONFIG_FILE}"
    log_message "Generated config file ${CONFIG_FILE}"
}

check_scripts_dest() {
    log_message "Running check_scripts_dest"
    clear

    echo "Check for existance of ${SCRIPTS_DEST}: "
    # Create SCRIPTS_DEST directory if it doesn't exist
    if [ ! -d "${SCRIPTS_DEST}" ]; then
        echo "Directory does not yet exist, let's create it."
        if echo "${PASSWORD}" | sudo -S mkdir -p "${SCRIPTS_DEST}" > /dev/null 2>&1; then
            log_message "${SCRIPTS_DEST} directory did not exist, created"
        else
            echo "Error: Failed to create ${SCRIPTS_DEST} directory. Exiting."
            log_message "Error: Failed to create ${SCRIPTS_DEST} directory"
            exit 1
        fi
    else
        echo "Directory already exists."
        log_message "${SCRIPTS_DEST} already exists"
    fi
    # Check if SCRIPTS_DEST directory is in the shell PATH
    if [[ ":$PATH:" != *":${SCRIPTS_DEST}:"* ]]; then
        echo "${SCRIPTS_DEST} is not in your shell PATH. Make sure to add that, before you start using the scripts."
        log_message "${SCRIPTS_DEST} not found in shell PATH"
    else
        echo "${SCRIPTS_DEST} is already in your PATH. You are good to go."
        log_message "${SCRIPTS_DEST} is present in shell PATH"
    fi
}

test_script_path() {
    local script_path="$1"
    local script_name=$(basename "${script_path}")
    local current_path=$(which "${script_name}")
    if [ "${current_path}" != "${script_path}" ]; then
        EXISTING_PATHS+=("${current_path}")
    fi
}

create_local_folders() {
    mkdir -p "${rootfolder}"
    log_message "${rootfolder} created"
    mkdir -p "${backupfolder}"
    log_message "${backupfolder} created"
}

install_local_scripts() {
    log_message "Running install_local_scripts"

    echo -e "Install local scripts:\n"
    for script in "${LOCAL_SCRIPTS[@]}"; do
        echo "- install ${script}."
        log_message "Install ${script}"

        # Download the script
        if ! curl -fsL "${GITHUB_BASE}/src/Scripts/${script}" -o "script.${script}"; then
            echo "Error: Failed to download ${script}. Skipping."
            log_message "Error: Failed to download ${script}"
            continue
        fi

        # Backup existing script if present
        if [ -f "${SCRIPTS_DEST}/${script}" ]; then
            if ! echo "${PASSWORD}" | sudo -S mv -f "${SCRIPTS_DEST}/${script}" "${SCRIPTS_DEST}/${script}.$(date +%Y%m%d-%H%M%S)" 2>/dev/null; then
                echo "Error: Failed to backup existing ${script}. Skipping."
                log_message "Error: Failed to backup ${script}"
                rm -f "script.${script}"
                continue
            fi
        fi

        # Install the new script
        if ! echo "${PASSWORD}" | sudo -S mv -f "script.${script}" "${SCRIPTS_DEST}/${script}" 2>/dev/null; then
            echo "Error: Failed to install ${script}. Skipping."
            log_message "Error: Failed to install ${script}"
            rm -f "script.${script}"
            continue
        fi

        # Make it executable
        if ! echo "${PASSWORD}" | sudo -S chmod +x "${SCRIPTS_DEST}/${script}" 2>/dev/null; then
            echo "Error: Failed to make ${script} executable. Skipping."
            log_message "Error: Failed to make ${script} executable"
            continue
        fi

        test_script_path "${SCRIPTS_DEST}/${script}"
    done
}

report_existing_paths() {
    log_message "Running report_existing_paths"
    if [ ${#EXISTING_PATHS[@]} -gt 0 ]; then
        echo -e "\n################"
        echo -e "## ATTENTION! ##"
        echo -e "################\n"
        echo -e "The following scripts are already installed in a different location than ${SCRIPTS_DEST}:\n"
        for path in "${EXISTING_PATHS[@]}"; do
            echo "- ${path}"
            log_message "Script already exists: ${path}"
        done
        echo -e "\nAll new scripts are installed in ${SCRIPTS_DEST}."
        echo "The scripts in the list above are still available in the old locations and these might come first in the PATH variable."
        echo -e "If you want to use the new development environment,\nyou MUST delete or rename the scripts in the old locations first!.\n"
        echo -e "Starting the new environment without cleaning up the old scripts first, will result in errors."
    fi
}

setup_shell_function() {
    log_message "Running setup_shell_function"

    # Detect the shell
    if [[ "$SHELL" == *"zsh"* ]]; then
        RC_FILE="${HOME}/.zshrc"
        SHELL_TYPE="zsh"
    elif [[ "$SHELL" == *"bash"* ]]; then
        RC_FILE="${HOME}/.bashrc"
        SHELL_TYPE="bash"
    else
        echo "Warning: Unsupported shell. gosite function not configured."
        log_message "Warning: Unsupported shell ($SHELL)"
        return
    fi

    # Check if function already exists in RC file
    if grep -q "^gosite()" "${RC_FILE}" 2>/dev/null; then
        echo "${SHELL_TYPE} configuration already has gosite function."
        log_message "gosite function already exists in ${RC_FILE}"
        return
    fi

    # Add the function to the RC file using printf
    if printf '\n# gosite function - enables cd to Joomla site with gosite command\ngosite() {\n    local RESULT\n    RESULT=$(command /usr/local/bin/gosite)\n    if [ $? -eq 0 ]; then\n        cd "$RESULT"\n    else\n        return 1\n    fi\n}\n' >> "${RC_FILE}"; then
        echo -e "\nAdded gosite function to ${RC_FILE}"
        log_message "Added gosite function to ${RC_FILE}"
        echo -e "To activate the gosite function now, run: source ${RC_FILE}\n"
        echo "It will be available automatically in all new terminal sessions."
    else
        echo "Error: Failed to add gosite function to ${RC_FILE}"
        log_message "Error: Failed to add gosite function to ${RC_FILE}"
    fi
}

the_end() {
    echo -e "\nInstallation completed."
    log_message "Installation completed"
    echo -e "The installation log is available at ${LOGFILE}.\n"
    echo "Enjoy DDEV with enhanced Joomla support!"
    echo "If you like this tool, please consider a donation to support further development: https://renekreijveld.nl/donate."
}

# Execute the script in order
create_config
start
prechecks
ask_defaults
source "${CONFIG_FILE}"
check_scripts_dest
create_local_folders
install_local_scripts
report_existing_paths
setup_shell_function
the_end