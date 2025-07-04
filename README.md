# PlayOn Recorder CLI

This tool provides a command-line interface (CLI) for interacting with the PlayOn Recorder API. The PlayOn Recorder is a service that records video streams from various sources, and this CLI allows you to manage your recordings, especially on Linux systems.

**Disclaimer:** This is a third-party tool and is not affiliated with PlayOn.

## Features

*   List your PlayOn recordings.
*   Download your recordings to your local machine.
*   Delete recordings from the PlayOn service.
*   Supports both password-based and secure KDE Wallet authentication.
*   Automate the process of downloading your recordings.

## Requirements

*   Linux (or macOS, though not officially tested)
*   Ruby ~> 3.1.4
*   Bundler ~> 2.2.17

## Installation

1.  **Install dependencies:**
    ```bash
    bundle install
    ```

2.  **Create a symbolic link** to the `playon` executable in a directory that is in your `PATH`. This will allow you to run the `playon` command from anywhere.
    ```bash
    # You may need to use sudo for this command
    ln -s "$(pwd)/bin/playon" /usr/local/bin/playon
    ```

## Getting Started

### 1. Authentication

Before you can use the tool, you need to authenticate with your PlayOn account. You only need to do this once. The tool will store your API credentials in a configuration file (`~/.config/playonrecorder/config.json`) for future use. Your password is **not** stored in this file.

There are two ways to authenticate:

*   **Password (less secure):**
    ```bash
    # Set the HISTCONTROL environment variable to prevent your password from being saved in your shell history
    export HISTCONTROL=ignoreboth
    export PLAYON_PASSWORD="your-playon-password"
    playon --email "your@email.com" auth
    ```

*   **KDE Wallet (more secure):**
    ```bash
    playon --email "your@email.com" auth --wallet "your-wallet-name" --folder "your-folder-name"
    ```
    For more information on setting up KDE Wallet, see the [KDE documentation](https://docs.kde.org/stable5/en/kwalletmanager/kwallet5/introduction.html).

### 2. Usage

Once you're authenticated, you can use the `videos` command to manage your recordings.

**List all recordings:**

```bash
playon videos ls
```

**Download all recordings:**

```bash
playon videos dl
```

**Delete all recordings:**

```bash
playon videos rm
```

You can also use various flags to filter and sort your videos. For example, to download all episodes of a specific series:

```bash
playon videos --by-series "My Favorite Show" dl
```

For a full list of available commands and options, you can use the `help` command:

```bash
playon help
playon help videos
playon videos --help
```

## Command Reference

<details>
<summary>Global Options</summary>

```
-c, --config=arg - config file (default: /home/jimconn/.config/playonrecorder/config.json)
--email=arg      - Email address used to auth to PlayOn Recorder (default: none)
--help           - Show this message
--verbose=arg    - Verbosity level (default: none)
```
</details>

<details>
<summary>Commands</summary>

*   `auth`: Manage credential management to the PlayOn Recorder
*   `videos`: Manage videos on the PlayOn Recorder
*   `help`: Shows a list of commands or help for one command

</details>

<details>
<summary>Videos Command Options</summary>

```
-a, --[no-]all     - show all videos (default: enabled)
--by-season=arg    - just show videos from this season(s) (may be used more than once, default: none)
--by-series=arg    - just show videos from this series(s) (may be used more than once, default: none)
--dl-path=arg      - path to which to download videos (default: /nas/nas-media-3/stage)
--[no-]force       - force download of videos even if they already exist
--[no-]progress    - show download progress (default: enabled)
-r, --[no-]reverse - reverse the sort order
-s, --sort-by=arg  - sort by size, title, episode, download-date, rating, expiry, or year (default: title)
--show-as=arg      - show output as table, json, yaml, or csv (default: table)
--title=arg        - find videos with named title(s). Regex friendly and case insensitive (may be used more than once, default: none)
```
</details>

## Development

For development purposes, you can build and run the application in a container.

```bash
bin/lxc-playon
```

This will build a Docker image and run the `playon` command inside the container. The initial build may take some time. Subsequent runs will be faster. You will need to have Docker installed.