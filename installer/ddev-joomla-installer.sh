#!/bin/bash

# ddev-joomla-installler - Install bash script to support Joomla running on DDEV
#
# Written by René Kreijveld - email@renekreijveld.nl
# This script is free software; you may redistribute it and/or modify it.
# This script comes without any warranty. Use it at your own risk, always backup your data and software before running this script.
#
# Version history
# 1.0 Initial version.

ERSION=1.0

# Folder where scripts are installed
HOMEBREW_PATH=$(brew --prefix)
SCRIPTS_DEST="/usr/local/bin"
CONFIG_DIR="${HOME}/.config/ddevjoomla"
INSTALL_LOG="${CONFIG_DIR}/ddev-joomla-install.log"
CONFIG_FILE="${CONFIG_DIR}/config"

# Local scripts to install
LOCAL_SCRIPTS=( "addsite" "jdbdump" "jdbimp" "latestjoomla" )

# GitHub Repo Base URL
GITHUB_BASE="https://github.com/renekreijveld/ddev-joomla/raw/refs/heads/main"

# Logged-in User
USERNAME=$(whoami)

EXISTING_PATHS=()

trap "echo 'Installation interrupted. Exiting...'; exit 1" SIGINT

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
    clear
    echo -e "Welcome to the DDEV support scripts for Joomla installer ${THISVERSION}.\n"
    echo -e "\t#########################################################"
    echo -e "\t## PLEASE READ EVERYTHING CAREFULLY BEFORE CONTINUING! ##"
    echo -e "\t#########################################################\n"
    echo "Installation output will be logged in the file ${INSTALL_LOG}."
    echo -e "Check this file if you encounter any issues during installation.\n"
    echo -e "This installer and the software it installs come without any warranty. Use it at your own risk.\nAlways backup your data and software before running the installer and use the software it installs.\n"
    read -p "Press Enter to start the installation, press Ctrl-C to abort. "
    touch "${INSTALL_LOG}"
}

# Function to check if a script is already installed
is_installed() {
    [ -f /usr/local/bin/$1 ]
}

prechecks() {
    clear
    echo "The installer will first check if the scripts are already installed."
    
    INSTALLED_SCRIPTS=()
    for script in "${LOCAL_SCRIPTS[@]}"; do
        if is_installed "${script}"; then
            INSTALLED_SCRIPTS+=("${script}")
        fi
    done

    if [ ${#INSTALLED_SCRIPTS[@]} -gt 0 ]; then
        echo -e "\nThe following scripts are already installed in /usr/local/bin:\n"
        for script in "${INSTALLED_SCRIPTS[@]}"; do
            echo "  - ${formula}"
        done
        echo -e "\nThis installer does not update these scripts but will make a backup of the original script.\n"
        read -p "Press Enter to start the installation, or press Ctrl-C to abort. "
    else
        echo "None of the scripts were already installed. Proceeding."
    fi
}

ask_defaults() {
    clear
    # Check if config file already exists and if so, backup it
    if [[ -f "${CONFIG_FILE}" ]]; then
        # Backup existing config file
        echo "The config file ${CONFIG_FILE} already exists, a backup will be created."
        BACKUPFILE="${CONFIG_FILE}.$(date +%Y%m%d-%H%M%S)"
        cp "${CONFIG_FILE}" "${BACKUPFILE}"
        echo "Existing config file backupped to ${BACKUPFILE}."
    fi

    # Create config directory if it doesn't exist
    mkdir -p "${CONFIG_DIR}"
    echo -e "\nBefore the installation starts, some default values need to be set."
    echo "These values will be used during installation and will be saved in a config file."
    echo "There are various scripts the depend on this config file. These scripts will not work without it."
    echo -e "\nThe location of the config file is ${CONFIG_FILE}.\n"
    echo -e "If the default proposed value is correct, just press Enter.\n"
    rootfolder=$(prompt_for_input "$HOME/Development/Sites" "Directory path where your websites will be stored:")
    webserver=$(prompt_for_input "nginx" "Default webserver for projects, nginx or apache:")
    echo -e "You will now be asked for your password, which is needed for the installation of the scripts.\n"
    echo -e "Your password will not be stored in a file, it is only used for the installation.\n"
    read -s -p "Your password: " PASSWORD

    # Write the values to the config file
    NOW=$(date +"%Y-%m-%d %H:%M:%S")
    echo "# Configuration file for php development environment" > "${CONFIG_FILE}"
    echo "# Generated at ${NOW}" >> "${CONFIG_FILE}"
    echo "ROOTFOLDER=${rootfolder}" >> "${CONFIG_FILE}"
    echo "WEBSERVER=${webserver}" >> "${CONFIG_FILE}"
    echo "INSTALLER_VERSION=${VERSION}" >> "${CONFIG_FILE}"
}

check_scripts_dest() {
    clear
    echo "Check for existance of ${SCRIPTS_DEST}."
    # Create SCRIPTS_DEST directory if it doesn't exist
    if [ ! -d "${SCRIPTS_DEST}" ]; then
        echo "${SCRIPTS_DEST} directory does not yet exist, let's create it."
        echo "${PASSWORD}" | sudo -S mkdir -p "${SCRIPTS_DEST}" > /dev/null
    else
        echo "${SCRIPTS_DEST} directory already exists."
    fi
    # Check if SCRIPTS_DEST directory is in the shell PATH
    if [[ ":$PATH:" != *":${SCRIPTS_DEST}:"* ]]; then
        echo "${SCRIPTS_DEST} is not in your shell PATH. Make sure to add that, before you start using the scripts."
    else
        echo "${SCRIPTS_DEST} is already in PATH. You're good to go :-)"
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
    mkdir -p "${ROOTFOLDER}"
}

install_local_scripts() {
    echo -e "\nInstall local scripts:"
    echo -e "If a script already exists, a backup copy will be made."
    for script in "${LOCAL_SCRIPTS[@]}"; do
        echo "- install ${script}."
        curl -fsSL "${GITHUB_BASE}/src/Scripts/${script}" | tee "script.${script}" > /dev/null

        if [ -f "${SCRIPTS_DEST}/${script}" ]; then
            echo "${PASSWORD}" | sudo -S mv -f "${SCRIPTS_DEST}/${script}" "${SCRIPTS_DEST}/${script}.$(date +%Y%m%d-%H%M%S)"
        fi

        echo "${PASSWORD}" | sudo -S mv -f "script.${script}" "${SCRIPTS_DEST}/${script}" > /dev/null
        echo "${PASSWORD}" | sudo -S chmod +x "${SCRIPTS_DEST}/${script}"
        test_script_path "${SCRIPTS_DEST}/${script}"
    done
}

report_existing_paths() {
    if [ ${#EXISTING_PATHS[@]} -gt 0 ]; then
        echo -e "\n################"
        echo -e "## ATTENTION! ##"
        echo -e "################\n"
        echo -e "The following scripts are already installed in a different location than ${SCRIPTS_DEST}:\n"
        for path in "${EXISTING_PATHS[@]}"; do
            echo "- ${path}"
        done
        echo -e "\nAll new scripts are installed in ${SCRIPTS_DEST}."
        echo "The scripts in the list above are still available in the old locations and these might come first in the PATH variable."
        echo -e "If you want to use the new development enviroment,\nyou MUST delete or rename the scripts in the old locations first!.\n"
        echo -e "Staring the new environment without cleaning up the old scripts first, will result in errors."
    fi
}

the_end() {
    echo -e "\nInstallation completed!\n"
    echo -e "The installation log is available at ${INSTALL_LOG}.\n"
    echo "Enjoy DDEV with enhanced Joomla support!"
    echo -e "\nIf you like this tool, please consider a donation to support further development: https://renekreijveld.nl/donate."
}

# Execute the script in order
start
prechecks
ask_defaults
source "${CONFIG_FILE}"
check_scripts_dest
create_local_folders
install_local_scripts
report_existing_paths
the_end