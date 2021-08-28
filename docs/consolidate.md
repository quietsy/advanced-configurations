# Consolidating Internal SWAG proxies

It's possible to consolidate the majority of internal nginx proxies using mappings, these mappings get resolved when the mapped variables are used.

**Note - This doesn't work for every app since some require special configuration, but it works for most of them.**

## Consolidated proxies

```Nginx
map $internal_app $internal_port {
    babybuddy 8000;
    bazarr 6767;
    bitwarden 80;
    collabora 9980;
    drawio 8080;
    gitea 3000;
    heimdall 4443;
    lidarr 8686;
    mkdocs 8000;
    paperless 8000;
    photoview 80;
    podgrab 8080;
    prowlarr 9696;
    radarr 7878;
    scrutiny 8080;
    sonarr 8989;
    uptime 3001;
    youtubedl 8080;
}
map $internal_app $internal_proto {
    default http;
    collabora https;
    heimdall https;
}
map $internal_app $internal_container {
    default $internal_app;
    bazarr "mullvad";
    lidarr "mullvad";
    podgrab "mullvad";
    prowlarr "mullvad";
    radarr "mullvad";
    sonarr "mullvad";
}
server {
    listen 443 ssl;
    server_name ~^(?<internal_app>.*?)\..*$;
    include /config/nginx/ssl.conf;
    client_max_body_size 0;
    if ($lan-ip = no) { return 404; }

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        proxy_pass $internal_proto://$internal_container:$internal_port;
    }
}
```

## Explanation

We created 3 mappings:

1. `map $internal_app $internal_container` - app name to the container name, with the app name by default.
2. `map $internal_app $internal_proto` - app name to the protocol, with `http` by default.
3. `map $internal_app $internal_port` - app name to the app port, with no default.

When a request comes in, it gets processed by the regular expression `~^(?<internal_app>.*?)\..*$` which sets `$internal_app` with the subdomain, for example radarr in the case of `radarr.domain.com`.

It then checks if the request is local, which requires [defining what is the local network](/secure/#geoblock).

The final part: `proxy_pass $internal_proto://$internal_container:$internal_port` figures out where to proxy the request based on the `$internal_app` variable, for example radarr gets proxied to `http://radarr:7878`.
