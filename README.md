# Omeka-S-Docker

A Docker development environment for Omeka S: Omeka S + MariaDB + Solr +
phpMyAdmin, driven by a small `otd` wrapper around `docker compose`.

Based on the [`webdevops/php-apache`](https://github.com/webdevops/Dockerfile)
image and the [`omeka-s-cli`](https://github.com/GhentCDH/Omeka-S-Cli) CLI.

## Requirements

- Docker Engine + the Docker Compose v2 plugin (`docker compose version` >= 2.20)
- ~2.5 GiB of free RAM (Solr is part of the default stack)
- `git` and a text editor

Your user must belong to the `docker` group:

```sh
sudo usermod -aG docker "$USER"   # then log out / restart your session
```

## Installation

```sh
mkdir -p ~/git && cd ~/git
git clone <this-repo-url> omeka-s-docker
```

### Environment variables

Create a `~/.omekas_env` file:

```sh
export OTD_HOME=~/git/omeka-s-docker
export PATH=$PATH:$OTD_HOME/bin
export LOCAL_UID=$(id -u)
export LOCAL_GID=$(id -g)
```

Have your shell load it on startup:

| Shell | Command |
| --- | --- |
| **bash** | `echo '[ -f ~/.omekas_env ] && . ~/.omekas_env' >> ~/.bashrc` |
| **zsh** | `echo '[ -f ~/.omekas_env ] && source ~/.omekas_env' >> ~/.zshrc` |
| **ksh / other POSIX shell** | add `. ~/.omekas_env` to `~/.profile` |
| **fish** | put the same values in `~/.config/fish/conf.d/omekas.fish` with `set -gx` + `fish_add_path $OTD_HOME/bin` |

Then reload the terminal (`exec $SHELL`) or source the file manually.

### Personal configuration

```sh
cd "$OTD_HOME"
cp env/defaults.env .env
$EDITOR .env        # Omeka/PHP/Solr version, admin credentials, modules...
```

`.env` is not versioned: it is your local configuration.

## Usage

```sh
otd up -d                 # start the stack, wait for it, print the URLs
otd --logs                # follow the omeka container logs
otd down                  # stop the stack (data is kept)
```

Interfaces: http://localhost:8080 (Omeka S), http://localhost:8081 (phpMyAdmin),
http://localhost:8983 (Solr).

`otd up -d` waits until every service is healthy; the first boot runs the core
install and module setup and can take a minute. `otd up` without `-d` streams the
full startup logs instead. `OTD_WAIT_TIMEOUT=<seconds>` changes the 300s timeout.

### Container access

```sh
otd --shell                          # shell in the omeka container (user "application")
otd --root --shell                   # same, as root
otd --run 'omeka-s-cli module:list'  # one-off command
otd --dbshell                        # database client on the omeka database
```

### Updating

```sh
cd "$OTD_HOME" && git pull
otd pull                    # refresh base images + rebuild the omeka image
otd --run reset_all         # if the schema changed
otd --root --run restart_all
```

## Modules

Two lists in `.env`:

| Variable | For | Behaviour |
| --- | --- | --- |
| `OMEKA_S_MODULES` | registry modules and ZIP URLs (published modules, in the [add-ons directory](https://omeka.org/add-ons/) or not) | downloaded at startup; installed when `OMEKA_S_INSTALL_MODULES=1` |
| `OMEKA_S_DEV_MODULES` | modules whose code you mount from the host | always installed/enabled at startup |

`OMEKA_S_MODULES` accepts `Name`, `Name:version`, or a ZIP URL, space-separated:

```
OMEKA_S_MODULES="Common Log EasyAdmin:3.4.38 https://github.com/acme/omeka-s-module-Foo/releases/download/v1.2.0/Foo-1.2.0.zip"
OMEKA_S_INSTALL_MODULES=1
```

### Modules whose code you have locally

Mount one module, or a directory of modules, from the host:

```sh
otd --module ~/git/omeka-s-module-MyModule up -d
otd --modules ~/git/omeka-modules up -d
```

A `--module` mount is installed/enabled automatically at startup (its name is
added to `OMEKA_S_DEV_MODULES` for that run). After a code change that bumps the
version in `config/module.ini`:

```sh
otd --run 'omeka-s-cli module:upgrade MyModule'
```

> `--modules DIR` replaces the whole `modules/` directory: modules bundled in the
> image or downloaded from the registry are then not visible. Prefer `--module`
> for a targeted mount.

## Search with Solr

Solr is part of the default stack (`SOLR_VERSION` / `SOLR_CORE` in `.env`), on
http://localhost:8983 with a `default` core. From the omeka container it is
`http://solr:8983/solr/default`.

Install the search modules via `OMEKA_S_MODULES` (e.g. `Search Solr` from
BibLibre, or `AdvancedSearch SearchSolr`), then configure the Solr node in the
Omeka admin using host `solr`, port `8983`, core `default` (not `localhost`).

Iterate on the schema:

```sh
otd --run solr-reload      # reload the core
otd --run solr-restart     # unload then recreate the core
```

## Mail testing

```sh
otd --smtp up -d
```

Adds Mailpit on http://localhost:8025 (SMTP on 1025). Omeka S is already
configured to send through it (`SMTP_*` in `.env`).

## In-container shortcuts

Via `otd --shell` or `otd --run '<name>'`:

| Command | Purpose | User |
| --- | --- | --- |
| `reset_all` | wipe the database, reinstall core and modules, run migrations | `otd --run` |
| `restart_all` | reload Apache / PHP | `otd --root --run` |
| `modules-install` | (re)install `OMEKA_S_MODULES` + `OMEKA_S_DEV_MODULES` | `otd --run` |
| `omeka-logs` | follow the application and Apache logs | `otd --run` |
| `omeka-cache-clear` | clear the Omeka on-disk cache | `otd --run` |
| `solr-reload` / `solr-restart` | reload / recreate the Solr core | `otd --run` |

## Configuration (`.env`)

See `env/defaults.env` for the full list. Main variables:

| Variable | Purpose | Default |
| --- | --- | --- |
| `OMEKA_S_VERSION`, `PHP_VERSION` | versions built into the image | `4.1.1` / `8.2` |
| `SOLR_VERSION`, `SOLR_CORE` | Solr service | `9` / `default` |
| `MARIADB_VERSION` | MariaDB version | `11.4` |
| `OMEKA_S_INSTALL_CORE` | install the core on first boot | `0` |
| `OMEKA_S_ADMIN_*`, `OMEKA_S_TITLE`, `OMEKA_S_LOCALE`, `OMEKA_S_TIME_ZONE` | installation parameters | — |
| `OMEKA_S_MODULES`, `OMEKA_S_DEV_MODULES`, `OMEKA_S_THEMES` | add-ons | — |
| `OMEKA_S_INSTALL_MODULES` | install `OMEKA_S_MODULES` at boot | `0` |
| `MYSQL_*` | database | `omeka` |
| `*_EXPOSED_PORT`, `MAILPIT_SMTP_PORT` | host-published ports | 8080 / 8081 / 8983 / 8025 / 1025 |
| `LOCAL_UID`, `LOCAL_GID` | application user UID/GID (injected by `otd`) | `1000` |

## Building a distributable image

```sh
./build_image.sh .env my-omeka-s:1.0.0
```

Builds an image tagged with the modules and themes listed in `OMEKA_S_MODULES` /
`OMEKA_S_THEMES`.

## Troubleshooting

- `otd up -d` reports "not healthy yet": `otd --logs` to find the failing startup
  script (`/entrypoint.d`); a slow first boot may just need a higher
  `OTD_WAIT_TIMEOUT`.
- Wrong ownership on mounted files: check `LOCAL_UID` / `LOCAL_GID` are exported.
- "database not empty" at startup: `otd down` then `otd up` again.

## Credits

Initial development by the
[Ghent Centre for Digital Humanities - Ghent University](https://www.ghentcdh.ugent.be/),
funded by the [GhentCDH research projects](https://www.ghentcdh.ugent.be/projects).
