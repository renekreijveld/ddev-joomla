# Bash scripts to support Joomla in DDEV

DDEV is a tool to create Docker-based PHP development environments. It gives you Container superpowers with zero required Docker skills: environments in minutes, multiple concurrent projects, and less time to deployment.

DDEV runs on macOS, Windows and Linux and on GitHub Codespaces.

This set of scripts were written to better support Joomla local development in DDEV.

### Features

- Create a new Joomla project and automatically download and install the latest Joomla version in it.
- Support for the /api endpoint when you run your Joomla project on Nginx.
- Create or import a MariaDB database dump from or to your Joomla project.

### Requirements

You need to have a working DDEV setup on your machine. Read about how to install DDEV here: <a href="https://ddev.com/get-started/" target="_blank">ddev.com/get-started</a>.

### Utility Scripts

The following scripts will be installed which do the following:

| Script | Purpose |
|--------|---------|
| `jaddsite` | Create a new DDEV Joomla project (PHP version, webserver, optional Joomla install) |
| `jlatest` | Download and extract the latest (or specified) Joomla release |
| `gosite` | Interactive selector to `cd` into a Joomla site (requires shell function wrapper in `.zshrc`/`.bashrc`) |
| `jdbdump` | Export the DDEV database (`ddev export-db`) |
| `jdbimp` | Import a database dump (`ddev import-db`) |
| `setrights` | Set correct file permissions (644 files, 755 dirs) |
| `jbackup` | Full site backup: database dump + compressed archive (`.tgz` or `.zip`) |
| `jddev` | Show all available scripts and their command-line parameters |


### Backup & Safety

The installer script automatically creates backups of all configuration files and existing scripts before making any changes.

### Installation & Updates

Follow these <a href="../../blob/main/Install.md">installation instructions</a> to get everything up and running.

Regular updates are provided in this repository. Use the <a href="../../blob/main/Update.md">update instructions</a> to keep your setup up to date.

### Support the Project

If you like and use this tool, please consider <a href="https://renekreijveld.nl/donate" target="_blank">making a donation</a> to support further development. 🙌
