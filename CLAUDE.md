# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ddev-joomla** is a collection of Bash scripts that enhance Joomla development workflows within [DDEV](https://ddev.com/), a Docker-based PHP development environment. The scripts automate creating, managing, and backing up Joomla installations.

## No Build or Test System

This project is pure Bash — no package manager, build tools, test framework, or CI/CD. Testing is manual. To validate a script change, run the script directly in a terminal with DDEV installed.

## Script Installation

Scripts are distributed via curl to `/usr/local/bin/` (requires sudo). The installer/updater fetch scripts from the GitHub `main` branch at runtime.

```bash
# Install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/renekreijveld/ddev-joomla/refs/heads/main/installer/ddev-joomla-installer.sh)"

# Update
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/renekreijveld/ddev-joomla/refs/heads/main/updater/ddev-joomla-updater.sh)"
```

## Architecture

### Configuration

All scripts share a single config file at `~/.config/ddevjoomla/config` with three key variables:
- `ROOTFOLDER` — where Joomla sites live (default: `$HOME/Development/sites`)
- `BACKUPFOLDER` — where backups go (default: `$HOME/Development/backup`)
- `WEBSERVER` — default webserver type (`nginx` or `apache`)

Each script sources this config at startup.

### Script Locations

- `src/Scripts/` — the deployable utility scripts (installed to `/usr/local/bin/`)
- `installer/ddev-joomla-installer.sh` — installs scripts and creates config
- `updater/ddev-joomla-updater.sh` — updates scripts from GitHub main branch

### Utility Scripts (`src/Scripts/`)

| `jaddsite` | Create a new DDEV Joomla project (PHP version, webserver, optional Joomla install) |
| `jdelsite` | Permanently delete a DDEV Joomla project and its files |
| `jlatest` | Download and extract the latest (or specified) Joomla release |
| `jdbdump` | Export the DDEV database (`ddev export-db`) |
| `jdbimp` | Import a database dump (`ddev import-db`) |
| `jbackup` | Full site backup: database dump + compressed archive (`.tgz` or `.zip`) |
| `gosite` | Interactive selector to `cd` into a Joomla site (requires shell function wrapper in `.zshrc`/`.bashrc`) |
| `setrights` | Set correct file permissions (644 files, 755 dirs) |
| `jddev` | Show all available scripts and their command-line parameters |
| `jddev-update` | Update all ddev-joomla scripts from the GitHub main branch |

### gosite Shell Function

`gosite` cannot change the calling shell's directory on its own. The installer adds a wrapper function to `.zshrc`/`.bashrc`:

```bash
function gosite() { cd "$(command gosite "$@")"; }
```

### jaddsite — DDEV Project Setup

When creating a project, `jaddsite`:
1. Creates the site directory under `ROOTFOLDER`
2. Runs `ddev config` with `--docroot=.` and the specified PHP/webserver
3. Writes `.ddev/php/joomla.ini` (sets `display_errors`, `output_buffering`)
4. For Nginx: appends Joomla API location block to `nginx-site.conf`
5. Installs the Adminer DDEV add-on
6. Optionally runs `jlatest` and the Joomla CLI installer with generated credentials

## Coding Conventions

- All scripts start with `#!/bin/bash`
- Version tracked in a `VERSION` variable near the top
- Config is loaded via `source ~/.config/ddevjoomla/config`
- Silent mode (`-s` flag) suppresses output; scripts still exit with correct codes
- Destructive actions prompt for confirmation unless `-o` (overwrite) is passed
- Errors print to stdout with a descriptive message and `exit 1`
- Always make sure the script can run in macOS, Windows with WLS and Linux.
