# SearXNG

[SearXNG](https://github.com/searxng/searxng) is a free metasearch engine with the aim of protecting the privacy of its users. To this end, Searx does not share users' IP addresses or search history with the search engines from which it gathers results. Tracking cookies served by the search engines are blocked, preventing user-profiling-based results modification.

## Installation
### Compose

```Yaml
  searxng:
    image: searxng/searxng
    container_name: searxng
    volumes:
      - /path/to/searxng:/etc/searxng
    environment:
      - BASE_URL=https://search.yourdomain.com/
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
        set $upstream_app searxng;
        set $upstream_port 8080;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

### Settings

The settings file is `/path/to/searx/settings.yml`, it can seem overwhelming but the majority of it are the search engine configuration which can be enabled/disabled from the UI.

These settings may require changing in the file:
```Yaml
# see https://docs.searxng.org/admin/engines/settings.html#use-default-settings
use_default_settings: true
general:
  debug: false
  instance_name: "Search"
  privacypolicy_url: false
  donation_url: false
  contact_url: false
  enable_metrics: false
server:
  secret_key: "CHANGE THIS"
  limiter: false  # can be disabled for a private instance
  image_proxy: true
ui:
  static_use_hash: true
  default_theme: simple
  theme_args:
    simple_style: dark
  infinite_scroll: true
  query_in_title: true
search:
  autocomplete: "duckduckgo"
  default_lang: "all"
enabled_plugins:
  - 'Hash plugin'
  - 'Search on category select'
  - 'Self Informations'
  - 'Tracker URL remover'
  - 'Hostnames plugin'
  - 'Open Access DOI rewrite'
  - 'Unit converter plugin'
hostnames:
  high_priority:
    - '(.*)\/blog\/(.*)'
    - '(.*\.)?wikipedia.org$'
    - '(.*\.)?github.com$'
    - '(.*\.)?reddit.com$'
    - '(.*\.)?linuxserver.io$'
    - '(.*\.)?docker.com$'
    - '(.*\.)?archlinux.org$'
    - '(.*\.)?stackoverflow.com$'
    - '(.*\.)?askubuntu.com$'
    - '(.*\.)?superuser.com$'
  remove:
    - '(.*\.)?facebook.com$'
    - '(.*\.)?instagram.com$'
    - '(.*\.)?codegrepper.com$'
    - '(.*\.)?w3schools.com$'
    - '(.*\.)?geeksforgeeks.org$'
    - '(.*\.)?stackshare.io$'
    - '(.*\.)?tutorialspoint.com$'
    - '(.*\.)?answeright.com$'
    - '(.*\.)?askdev.info$'
    - '(.*\.)?askdev.io$'
    - '(.*\.)?blogmepost.com$'
    - '(.*\.)?c-sharpcorner.com$'
    - '(.*\.)?code-examples.net$'
    - '(.*\.)?codeflow.site$'
    - '(.*\.)?gitmemory.cn$'
    - '(.*\.)?gitmemory.com$'
    - '(.*\.)?intellipaat.com$'
    - '(.*\.)?javaer101.com$'
    - '(.*\.)?programmerstart.com$'
    - '(.*\.)?programmersought.com$'
    - '(.*\.)?qastack.com$'
    - '(.*\.)?roboflow.ai$'
    - '(.*\.)?stackanswers.net$'
    - '(.*\.)?stackoom.com$'
    - '(.*\.)?stackovernet.com$'
    - '(.*\.)?stackovernet.xyz$'
    - '(.*\.)?stackoverrun.com$'
    - '(.*\.)?thetopsites.net$'
    - '(.*\.)?ubuntugeeks.com$'
    - '(.*\.)?cyberciti.biz$'
    - '(.*\.)?ispycode.com$'
    - '(.*\.)?reposhub.com$'
    - '(.*\.)?githubmemory.com$'
    - '(.*\.)?issueexplorer.com$'
    - '(.*\.)?tabnine.com$'
    - '(.*\.)?gitcode.net$'
    - '(.*\.)?command-not-found.com$'
    - '(.*\.)?im-coder.com$'
    - '(.*\.)?i-harness.com$'
  replace:
    '(.*\.)?reddit.com$': 'some.redlib.com'
    '(.*\.)?redd.it$': 'some.redlib.com'
    '(.*\.)?youtube.com$': 'some.piped.com'
    '(.*\.)?youtu.be$': 'some.piped.com'
```

## Rate Limiting (Optional)

Rate limiting can be enabled by adding a redis container and setting these:
```Yaml
server:
  limiter: true  # can be disabled for a private instance
redis:
  url: redis://redis:6379/0
```

An example compose can be found [here](https://github.com/searxng/searxng-docker).
