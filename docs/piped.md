# Piped - Getting Started

[Piped](https://github.com/TeamPiped/Piped) is an alternative YouTube frontend which is efficient by design.

## Compose

Create the following containers:

```YAML
  pipeddb:
    image: postgres:13-alpine
    container_name: pipeddb
    volumes:
      - /path/to/pipeddb:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=piped
      - POSTGRES_USER=piped
      - POSTGRES_PASSWORD=<PASSWORD> # Set a database password
    restart: always

  pipedproxy:
    image: 1337kavin/ytproxy
    container_name: pipedproxy
    user: "1000:1000" # Replace with the user and group IDs
    volumes:
      - /path/to/pipedproxy:/app/socket
    restart: always

  pipedfe:
    image: 1337kavin/piped-frontend
    container_name: pipedfe
    # Replace pipedapi.mydomain.com with the API subdomain
    entrypoint: ash -c 'sed -i s/pipedapi.kavin.rocks/pipedapi.mydomain.com/g /usr/share/nginx/html/assets/* && /docker-entrypoint.sh && nginx -g "daemon off;"' 
    restart: always

  pipedapi:
    image: 1337kavin/piped
    container_name: pipedapi
    volumes:
      - /path/to/piped/config.properties:/app/config.properties:ro
    restart: always
```

You may need to `chown -R 1000:1000 /path/to/pipedproxy` with your user and group ID.

## Configuration

Set the following configuration in `/path/to/piped/config.properties`:

```YAML
# The port to Listen on.
PORT: 8080

# The number of workers to use for the server
HTTP_WORKERS: 2

# Proxy
PROXY_PART: https://pipedproxy.mydomain.com

# Outgoing HTTP Proxy - eg: 127.0.0.1:8118
#HTTP_PROXY: 127.0.0.1:8118

FRONTEND_URL: https://piped.mydomain.com

# Captcha Parameters
#CAPTCHA_BASE_URL: https://api.capmonster.cloud/
#CAPTCHA_API_KEY: INSERT_HERE

# Public API URL
API_URL: https://pipedapi.mydomain.com

# Hibernate properties
hibernate.connection.url: jdbc:postgresql://pipeddb:5432/piped
hibernate.connection.driver_class: org.postgresql.Driver
hibernate.dialect: org.hibernate.dialect.PostgreSQL10Dialect
hibernate.connection.username: piped
hibernate.connection.password: <PASSWORD> # Replace with the database password

```

## Reverse Proxy

```Nginx
server {
    listen 443 ssl;
    server_name piped.mydomain.com; # Set the API domain
    include /config/nginx/ssl.conf;
    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app pipedfe;
        set $upstream_port 80;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}

server {
    listen 443 ssl;
    server_name pipedapi.mydomain.com; # Set the frontend domain
    include /config/nginx/ssl.conf;
    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app pipedapi;
        set $upstream_port 8080;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
    location /webhooks/pubsub {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app pipedapi;
        set $upstream_port 8080;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}

server {
    listen 443 ssl;
    server_name pipedproxy.mydomain.com; # Set the proxy domain
    include /config/nginx/ssl.conf;
    client_max_body_size 0;

    location ~ (/videoplayback|/api/v4/|/api/manifest/) {
        proxy_pass http://unix:/var/run/ytproxy/http-proxy.sock;
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Headers *;
        if ($request_method = OPTIONS ) {
            return 200;
        }
        proxy_buffering on;
        proxy_set_header Host $arg_host;
        proxy_ssl_server_name on;
        proxy_set_header X-Forwarded-For "";
        proxy_set_header CF-Connecting-IP "";
        proxy_hide_header "alt-svc";
        sendfile on;
        sendfile_max_chunk 512k;
        tcp_nopush on;
        aio threads=default;
        aio_write on;
        directio 2m;
        proxy_hide_header Cache-Control;
        proxy_hide_header etag;
        proxy_http_version 1.1;
        proxy_set_header Connection keep-alive;
        proxy_max_temp_file_size 0;
        access_log off;
        add_header Cache-Control private always;
        proxy_hide_header Access-Control-Allow-Origin;
    }

    location / {
        proxy_pass http://unix:/var/run/ytproxy/http-proxy.sock;
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Headers *;
        if ($request_method = OPTIONS ) {
            return 200;
        }
        proxy_buffering on;
        proxy_set_header Host $arg_host;
        proxy_ssl_server_name on;
        proxy_set_header X-Forwarded-For "";
        proxy_set_header CF-Connecting-IP "";
        proxy_hide_header "alt-svc";
        sendfile on;
        sendfile_max_chunk 512k;
        tcp_nopush on;
        aio threads=default;
        aio_write on;
        directio 2m;
        proxy_hide_header Cache-Control;
        proxy_hide_header etag;
        proxy_http_version 1.1;
        proxy_set_header Connection keep-alive;
        proxy_max_temp_file_size 0;
        access_log off;
        add_header Cache-Control "public, max-age=604800";
        proxy_hide_header Access-Control-Allow-Origin;
    }
}

```

All the sub-domains can remain internal-only except for the following domain that must be exposed for subscriptions to work:

```nginx
    location /webhooks/pubsub {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app pipedapi;
        set $upstream_port 8080;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
```

And finally, add the following volume to SWAG:
```nginx
  - /path/to/pipedproxy:/var/run/ytproxy
```