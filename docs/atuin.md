# Atuin

[Atuin](https://docs.atuin.sh/) replaces your existing shell history with a SQLite database, and records additional context for your commands. With this context, Atuin gives you faster and better search of your shell history.

Atuin also syncs your shell history between all of your machines. Fully end-to-end encrypted.

## Server

Change the version to the latest.

```yaml
  atuin:
    image: ghcr.io/atuinsh/atuin:v18.1.0
    container_name: atuin
    user: "${PUID}:${PGID}"
    command: server start
    environment:
      ATUIN_HOST: "0.0.0.0"
      ATUIN_OPEN_REGISTRATION: "true"
      ATUIN_DB_URI: postgres://${MYUSER}:${MYPASSWORD}@atuindb/atuin
    volumes:
      - "${APPSDIR}/atuin/config:/config"
    restart: always
  atuindb:
    image: postgres:14-alpine
    container_name: atuindb
    user: "${PUID}:${PGID}"
    environment:
      POSTGRES_USER: ${MYUSER}
      POSTGRES_PASSWORD: ${MYPASSWORD}
      POSTGRES_DB: atuin
    volumes:
      - ${APPSDIR}/atuin/db:/var/lib/postgresql/data
    restart: always
```

## Client Installation

### Linux

```bash
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
```

### Termux

```bash
pkg install atuin
```

### OPNSense

Enable the freebsd repo in `/usr/local/etc/pkg/repos/FreeBSD.conf` and run:

```bash
pkg update
pkg install atuin
```

## Configuration

Run:

```bash
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
atuin gen-completions --shell zsh --out-dir $HOME
```

Edit `~/.config/atuin/config.toml`:

```ini
dialect = "uk"
auto_sync = true
update_check = true
sync_address = "https://atuin.domain.com"
sync_frequency = "0"
filter_mode = "global"
workspaces = true
filter_mode_shell_up_key_binding = "host"
style = "compact"
enter_accept = true

[sync]
records = true
```

## Initialization

```bash
atuin register -u <USERNAME> -e <EMAIL>
atuin import auto
atuin sync -f
```

## New Machine

```bash
atuin login -u <USERNAME>
atuin import auto
atuin sync -f
```

## Usage

[Atuin documentation](https://docs.atuin.sh/)