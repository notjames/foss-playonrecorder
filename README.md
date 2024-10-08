# playon

This tool interfaces with the PlayOn Recorder API. The PlayOn Recorder is a service that records
video streams from various sources. The API is used to manage the videos on that service. See 
[PlayOn Service](https://www.playon.tv/) for more information.

DISCLAIMER: This tool is not affiliated with PlayOn. It is a third-party tool that interfaces
with the PlayOn Recorder API.

PlayOn provides a tool for Windows and Mac users that will allow them to manage their recordings.
The purpose behind this tool was to make something similar for Linux and make it simple to automate
downloads of your video recordings from the PlayOn service. PlayOn is not free, but it's a very useful
service if you need a way to get your Vudu recordings migrated to your local media server and such.

`playon` has two main command arguments, `auth` and `videos`.

* `auth` is used to manage the credentials used to authenticate to the PlayOn Recorder.
* `videos` is used to manage the videos on the PlayOn Recorder.

## TL;DR

### Requirements

* Linux (or Darwin should work, too, but it's not tested)
* Ruby ~> 3.1.4
* Bundler ~> 2.2.17

### Installation

```
$ bundle install
# you might have to run `sudo` for the following command
$ ln -s $(pwd)/bin/playon /usr/local/bin/playon
```

**(container runtime is not fully working yet!!!)**

...or run `bin/lxc-playon` which will build a docker image and run 
the `playon` command in the container. Note that the initial build will take a minute or so.
Subsequent runs will be faster but not as fast as running the command directly from your machine.
Obviously, you'll need to have `docker` installed.

### Authentication

* Password auth
```
# set HISTCONTROL to ignoreboth so that your password is not stored in your history
export HISTCONTROL=ignoreboth; export PLAYON_PASSWORD=your-password
bin/playon --email your@email.com auth
```
  * Wallet

```
bin/playon --email your@email.com auth --wallet <wallet-name> --folder <folder-name> [--entry <entry-name>]
```

### Videos:

* list
```
❯ bin/playon videos [--switch <args>]... ls
```
* download
```
❯ bin/playon videos [--switch <args>]... dl
```
* delete
```
❯ bin/playon videos [--switch <args>]... rm
```

The main thing to remember is that the args for video actions are provided to the `video` command.
The subcommands are `ls`, `dl`, and `rm`.

#### Help Usage

`help` command is available for all commands and subcommands. `help` (without -- prefix) is always
used before the command or subcommand, and `help` (with -- prefix) is used after the command or subcommand.

```shell
❯ bin/playon help
❯ bin/playon help videos
❯ bin/playon videos --help
```

## Documentation

#### Global Scope Arguments

##### NAME
```shell
    playon - Playon Recorder API CLI Tool
```

##### SYNOPSIS
```shell
    playon [global options] command [command options] [arguments...]
```

##### GLOBAL OPTIONS
```shell
    -c, --config=arg - config file (default: /home/jimconn/.config/playonrecorder/config.json)
    --email=arg      - Email address used to auth to PlayOn Recorder (default: none)
    --help           - Show this message
    --verbose=arg    - Verbosity level (default: none)
```

##### COMMANDS
```shell
    auth   - Manage credential management to the PlayOn Recorder
    help   - Shows a list of commands or help for one command
    videos - Manage videos on the PlayOn Recorder
```

#### Auth Arguments

##### NAME
```shell
    auth - Manage credential management to the PlayOn Recorder
```

##### SYNOPSIS
```shell
    playon [global options] auth [command options]

```

##### COMMAND OPTIONS
```shell
    --entry=arg  - Name of the entry in the KDE wallet (default: < --email parameter >)
    --folder=arg - Name of the folder in the KDE wallet (default: playonrecorder)
    --wallet=arg - Name of the KDE wallet to use (default: none)
```

#### Videos Arguments

##### NAME
```shell
    videos - Manage videos on the PlayOn Recorder
```

##### SYNOPSIS
```shell
    playon [global options] videos [command options] dl

    playon [global options] videos [command options] ls

    playon [global options] videos [command options] rm
```

##### COMMAND OPTIONS
```shell
  COMMAND OPTIONS
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

##### COMMANDS
```shell
    dl, download - Download videos from the PlayOn Recorder
    ls, list     - List videos on the PlayOn Recorder
    rm, delete   - Delete videos on the PlayOn Recorder
```

### Authentication

Authentication currently supports two methods. One is basic authentication using the `--email` parameter.
The password must be stored in the `PLAYON_PASSWORD` environment variable or it will be asked for on the
command line. This is the least secure and desirable method of authentication. It's also the harder method
for automation.

The other is using the KDE wallet.  The KDE wallet is the only system wallet supported for now. The KDE
wallet is a secure way to store credentials on a Linux system. The `--entry` parameter is the name of the
entry in the KDE wallet. By default, it will use the `--email` argument if `--entry` is not specified.
The `--folder` parameter is the name of the folder in the KDE wallet. The `--wallet`
parameter is the name of the KDE wallet to use.

NOTE: Once you've authenticated, the API credentials are stored in the config file. The config file is
stored. The default location for that file is `$HOME/.config/playonrecorder/config.json`. Your password
is **NOT** stored in the config file. The config file is used to store the API key and the session token.

Subsequent calls to the `playon` command will use the API key and session token stored in the config file
to authenticate. The token will get renewed automatically, so technically, you need only autheticate once.

## Examples

#### Authentication

##### Basic Authentication
```
# set HISTCONTROL to ignoreboth so that your password is not stored in your history
export HISTCONTROL=ignoreboth; export PLAYON_PASSWORD=your-password
bin/playon --email your@email.com auth
```

##### Wallet

```shell
bin/playon --email your@email.com auth --wallet <wallet-name> --folder <folder-name> [--entry <entry-name>]
```

`--entry` is required bug if not provided, it will use the `--email` argument as the entry name.

##### Configuring Wallet

This topic is outside the scope of this document. However, one can find documentation [here in the KDE documentation](https://docs.kde.org/stable5/en/kwalletmanager/kwallet5/introduction.html).

#### Videos

* listing
```
❯ bin/playon videos [--switch <args>]... ls
```
* downloading
```
❯ bin/playon videos [--switch <args>]... dl
```
* deleting
```
❯ bin/playon videos [--switch <args>]... rm
```


## Development

Building the docker image: see `bin/lxc-playon`
