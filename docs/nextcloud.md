# Optimizing Nextcloud

The following is a collection of ways to optimize Nextcloud's performance and responsiveness.

## Optimization Steps

- Use the [LSIO image](https://github.com/linuxserver/docker-nextcloud), not the official
- Use the php8 tag
- Enable redis
- Use mariadb (alpine) or postgres
- Use nextcloud v22 or higher
- Add the following to `/config/php/php-local.ini`

```INI
memory_limit = -1
opcache.enable = 1
opcache.enable_cli = 1
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.memory_consumption = 128
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
  'filesystem_check_changes' => 1,
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'redis',
    'port' => 6379,
  ),
```

## Example Compose
```Yaml
  nextcloud:
    image: ghcr.io/linuxserver/nextcloud:php8
    container_name: nextcloud
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /path/to/appdata:/config
      - /path/to/data:/data
    restart: unless-stopped
    depends_on:
      - mariadb
      - redis
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
