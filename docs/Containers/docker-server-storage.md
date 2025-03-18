# Docker Server Storage

Docker server storage can be divided into 3 buckets:

- NVMe - fast storage for important data.
- SSD - disposable data.
- HDD - slow storage for important data.

## NVMe

Fast storage, ideally on high endurance NVMe, ideally in a ZFS mirror with snapshots.

Contains:

- Host OS
- Container config bind mounts
- Databases
- Small data that benefits from fast storage

## SSD

Cheap SSD, disposable data that shouldn't reduce the lifespan of the NVMe and doesn't require ZFS redundancy or snapshots.

Contains:

- Caches
- Logs
- Media transcodes
- Docker images and image volumes, change `data-root` under `/etc/docker/daemon.json`

    ```json
    {
            "data-root": "/mnt/cache/docker",
            "storage-driver": "overlay2"
    }
    ```

## HDD

Slow storage, ideally in a ZFS mirror/raidz with snapshots.

Contains:

- Media
- Photos
- Documents
- Large data
- Backup of NVMe data

## Investigating Writes

Install `fatrace`

```bash
sudo apt install fatrace
```

Record writes for 60 seconds

```bash
sudo fatrace -f W -o /tmp/fatrace -s 60
```

Sort by count

```bash
sort /tmp/fatrace | uniq -c | sort -n -r | more
```

Example output

```
    271 beam.smp(65906): W   /home/user/docker-data/pinchflat/db/pinchflat.db-wal
    166 nginx(270970): W   /home/user/docker-data/swag/log/nginx/access.log
     60 Radarr(67147): W   /home/user/docker-data/arr/radarr/radarr.db-wal
     57 Prowlarr(67150): W   /home/user/docker-data/arr/prowlarr/prowlarr.db-wal
     46 fail2ban-client(68766): W   /home/user/docker-data/swag/fail2ban/fail2ban.sqlite3
     45 Radarr(67147): W   /home/user/docker-data/arr/radarr/radarr.db-shm
     40 Lidarr(67160): W   /home/user/docker-data/arr/lidarr/lidarr.db-wal
     40 dockerd(57396): W   /mnt/cache/docker/containers/uuid/uuid-json.log
     39 Prowlarr(67150): W   /home/user/docker-data/arr/prowlarr/prowlarr.db-shm
     33 Radarr(67147): W   /home/user/docker-data/arr/radarr/radarr.db
     32 postgres(61541): W   /home/user/docker-data/atuin/db/pg_stat_tmp/db_16384.tmp
     32 dockerd(57396): W   /mnt/cache/docker/containers/uuid/uuid-json.log
     28 Prowlarr(67150): W   /home/user/docker-data/arr/prowlarr/logs.db-wal
     26 Sonarr(67148): W   /home/user/docker-data/arr/sonarr/logs.db-wal
     26 Radarr(67147): W   /home/user/docker-data/arr/radarr/logs.db-shm
     25 Prowlarr(67150): W   /home/user/docker-data/arr/prowlarr/prowlarr.db
     19 Radarr(67147): CW  /home/user/docker-data/arr/radarr/radarr.db-wal
     17 Radarr(67147): W   /home/user/docker-data/arr/radarr/logs.db-wal
     17 Radarr(67147): W   /home/user/docker-data/arr/radarr/logs.db
     17 Radarr(67147): CW  /home/user/docker-data/arr/radarr/radarr.db
     16 beszel(61939): W   /home/user/docker-data/beszel/data.db-wal
```