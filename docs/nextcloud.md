# Optimizing Nextcloud

The following is a collection of ways to optimize Nextcloud's performance and responsiveness.

## Optimization Steps

- Use the [LSIO image](https://github.com/linuxserver/docker-nextcloud), not the official
- Use the latest tag which includes php8
- Enable redis
- Use mariadb (alpine) or postgres
- Use nextcloud v22 or higher
- Use imaginary to speed up thumbnail creation
- Add the following to `/config/php/php-local.ini`

```INI
memory_limit = -1
opcache.enable = 1
opcache.enable_cli = 1
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 130987
opcache.memory_consumption = 256
opcache.save_comments = 1
opcache.revalidate_freq = 1
```

- Add the following to `/config/php/www2.conf`
```INI
pm = dynamic
pm.max_children = 120
pm.start_servers = 12
pm.min_spare_servers = 6
pm.max_spare_servers = 18
```
- Disable Dark Reader extension on it, if you use it
- For Nextcloud to identify filesystem changes, add the following to the config:
```js
  'filesystem_check_changes' => 1,
```
- Move `/config` to a fast disk such as nvme and mount it from there
- After the initial run move `/data/appdata_INSTANCEID` to a fast disk such as nvme and mount it from there, add the following under `volumes:`: (the ID in the directory names will be different)
```Yaml
      - /path/to/appdata/appdata_ocytnd8b2l1b:/data/appdata_ocytnd8b2l1b
```


## Example Nextcloud Config
Located in `/config/www/nextcloud/config/config.php`
```js
  'dbname' => 'nextcloud',
  'dbhost' => 'mariadb',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud_user',
  'dbpassword' => 'DATABASE_PASSWORD',
  'trusted_proxies' => ['172.16.0.0/12'],
  'filesystem_check_changes' => 1,
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'enable_previews' => true,
  'enabledPreviewProviders' => 
  array (
    0 => 'OC\\Preview\\Imaginary',
    1 => 'OC\\Preview\\Movie',
    2 => 'OC\\Preview\\MP4',
  ),
  'preview_imaginary_url' => 'http://imaginary:9000',
  'redis' => 
  array (
    'host' => 'redis',
    'port' => 6379,
  ),
```

## Example Compose
```Yaml
  nextcloud:
    image: ghcr.io/linuxserver/nextcloud:latest
    container_name: nextcloud
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /path/to/appdata:/config
      - /path/to/data:/data
      - /path/to/appdata/appdata_ocytnd8b2l1b:/data/appdata_ocytnd8b2l1b
    restart: unless-stopped
    depends_on:
      - mariadb
      - redis
      - imaginary
  imaginary:
    image: nextcloud/aio-imaginary:latest
    container_name: imaginary
    restart: unless-stopped
  redis:
    image: redis:alpine
    container_name: redis
    restart: unless-stopped
  mariadb:
    image: ghcr.io/linuxserver/mariadb
    container_name: mariadb
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud_user
      - MYSQL_PASSWORD=DATABASE_PASSWORD
      - MYSQL_ROOT_PASSWORD=ROOT_ACCESS_PASSWORD
    volumes:
      - /path/to/appdata:/config
    restart: unless-stopped
```
