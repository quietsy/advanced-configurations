# YAML Anchors

Using YAML anchors is a great way to reduce configuration duplication and be able to add configuration to all containers in a single place.

## Basic

You want all containers to have the same restart policy and the same memory limit of 2GB:

```Yaml
version: "3.9"

x-base: &base
  mem_limit: 2000m
  restart: always

services:
  radarr:
    <<: *base
    image: lscr.io/linuxserver/radarr
    container_name: radarr
    volumes:
      - ${APPSDIR}/radarr:/config
      - ${DATADIR}/media:/media
  sonarr:
    <<: *base
    image: lscr.io/linuxserver/sonarr
    container_name: sonarr
    volumes:
      - ${APPSDIR}/sonarr:/config
      - ${DATADIR}/media:/media
```

Every container with `<<: *base` will include everything listed under `x-base`, and changes to it will affect all containers.

## Advanced

You have a few common templates, and you want to be able to use all of them:

- `base` - The base of containers, you can safely assume that changes to it will affect all containers.
- `internalbase` - The base + associating with the internal docker network.
- `vpnbase` - The base + associating with the VPN network.
- `lsio` - Common environment variables in all LSIO containers.
- `lsiobase` - The base + associating with the internal docker network + LSIO variables.
- `vpnlsiobase` - The base + associating with the VPN network + LSIO variables.

```Yaml
version: "3.9"

x-base: &base
  mem_limit: 2000m
  restart: always 
x-internalbase: &internalbase
  <<: *base
  networks:
    - internal
x-vpnbase: &vpnbase
  <<: *base
  network_mode: "service:vpn"
x-lsio: &lsio
  PUID: ${PUID}
  PGID: ${PGID}
  TZ: ${TZ}
x-lsiobase: &lsiobase
  <<: *internalbase
  environment:
    <<: *lsio
x-vpnlsiobase: &vpnlsiobase
  <<: *vpnbase
  environment:
    <<: *lsio

services:
  radarr:
    <<: *lsiobase
    image: lscr.io/linuxserver/radarr
    container_name: radarr
    volumes:
      - ${APPSDIR}/radarr:/config
      - ${DATADIR}/media:/media
  sonarr:
    <<: *lsiobase
    image: lscr.io/linuxserver/sonarr
    container_name: sonarr
    volumes:
      - ${APPSDIR}/sonarr:/config
      - ${DATADIR}/media:/media
  lidarr:
    <<: *vpnlsiobase
    image: lscr.io/linuxserver/lidarr:nightly
    container_name: lidarr
    volumes:
      - ${APPSDIR}/lidarr:/config
      - ${DATADIR}/media:/media
  prowlarr:
    <<: *vpnlsiobase
    image: lscr.io/linuxserver/prowlarr:nightly-alpine
    container_name: prowlarr
    volumes:
      - ${APPSDIR}/prowlarr:/config
  ombi:
    <<: *vpnlsiobase
    image: lscr.io/linuxserver/ombi:development
    container_name: ombi
    volumes:
      - ${APPSDIR}/ombi4:/config
  collabora:
    <<: *internalbase
    image: collabora/code
    container_name: collabora
    environment:
      domain: ${CLBDOMAIN}
      dictionaries: en_US
```

We easily associated 2 containers with `lsiobase`, 3 with `vpnlsiobase`, and 1 with `internalbase`.

## Overriding Anchors

There may be a need to add environment variables beyond the ones defined in the base anchor, unfortunately when declaring the same section again it will override the base, not append to it.
Instead, you need to make a separate anchor for the environment variables and use it directly.

For example:

```yaml
x-base: &base
  mem_limit: 2000m
  restart: always 
x-internalbase: &internalbase
  <<: *base
  networks:
    - internal
x-lsio: &lsio
  PUID: ${PUID}
  PGID: ${PGID}
  TZ: ${TZ}
x-lsiobase: &lsiobase
  <<: *internalbase
  environment:
    <<: *lsio

services:
  mariadb:
    <<: *internalbase
    image: lscr.io/linuxserver/mariadb
    container_name: mariadb
    environment:
      <<: *lsio
      MYSQL_DIR: /config
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - ${APPSDIR}/mariadb:/config
```
