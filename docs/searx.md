# Searx

[Searx](https://github.com/searx/searx) is a free metasearch engine with the aim of protecting the privacy of its users. To this end, Searx does not share users' IP addresses or search history with the search engines from which it gathers results. Tracking cookies served by the search engines are blocked, preventing user-profiling-based results modification.

## Installation
### Compose

```Yaml
  searx:
    image: searxng/searxng
    container_name: searx
    volumes:
      - /path/to/searx:/etc/searx
    environment:
      - BASE_URL=https://search.yourdomain.com/
      - INSTANCE_NAME=Searx
    ports:
      - 8080:8080
    restart: always
```

### Reverse Proxy

```Nginx
server {
    listen 443 ssl;
    server_name search.yourdomain.com;
    include /config/nginx/ssl.conf;
    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app searx;
        set $upstream_port 8080;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

### Settings

The settings file can be found under `/path/to/searx/settings.yml`, it can seem quite intimidating but the majority of it are the search engine configuration which can be enabled/disabled from the UI.

These settings may require changing from the file:
```Yaml
general:
  instance_name: "Searx" # The name that is displayed
search:
  safe_search: 1 # Otherwise you may get inappropriate image results
  autocomplete: "google" # Or one of the other autocomplete sources
server:
  secret_key: "MUST CHANGE THIS"
  http_protocol_version: "1.1"
ui:
  advanced_search: true # Show the advanced options by default
  theme_args:
    oscar_style: logicodev-dark # Dark theme
enabled_plugins: # Enable plugins https://searx.github.io/searx/admin/plugins.html?highlight=plugins
  - "Infinite scroll"
  - "Tracker URL remover"
  - "Search on category select"
  - "Hash plugin"
  - "Self Informations"
engines:
  - name: <some engine>
    disabled: true # To disable any engine by default, add this line to it
```

## Morty Proxy (Optional)

Morty rewrites web pages to exclude malicious HTML tags and attributes. It also replaces external resource references to prevent third party information leaks.

### Compose

```Yaml  
morty:
    image: dalf/morty
    container_name: morty
    environment:
      - MORTY_ADDRESS=0.0.0.0:3000
      - DEBUG=false
    ports:
      - 3000:3000
    restart: always
```

### Reverse Proxy

```Nginx
server {
    listen 443 ssl;
    server_name proxy.yourdomain.com;
    include /config/nginx/ssl.conf;
    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app morty;
        set $upstream_port 3000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

### Settings

Enable the proxy with the following settings:
```Yaml
server:
  image_proxy: true
result_proxy:
  url: https://proxy.yourdomain.com/
```

## Filtron (Optional)

If you want to make your instance public, you may want to configure [Filtron](https://github.com/asciimoo/filtron), I won't go into it.
