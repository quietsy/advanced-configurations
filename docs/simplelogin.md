# Simplelogin

## Strategy

![simplelogin](images/simplelogin.png)

## Notes

- [Check the reputation](https://www.uceprotect.net/en/rblcheck.php) of your VPS IP before proceeding.
- Follow the [official documentation](https://github.com/simple-login/app) to set up the domain.
- Read about each environment variable of [simplelogin](https://github.com/simple-login/app/blob/master/example.env) and [postfix](https://github.com/simple-login/simplelogin-postfix-docker).
- Using SWAG to generate certs and then mounting the certs to postfix.
- SWAG has the following post-renewal hook under `./swag/etc/letsencrypt/renewal-hooks/post/postfix.sh`:

    ```bash
    #!/usr/bin/with-contenv bash

    touch /config/etc/letsencrypt/postfix_renew
    ```

- Postfix has the following script mounted to `/etc/periodic/hourly/renew-postfix-tls` for reloading on cert updates:

    ```bash
    #!/usr/bin/env bash

    set -e

    if [ -f ${RENEW_PATH} ]; then
        /src/generate_config.py --postfix
        postfix reload
        rm -f ${RENEW_PATH}
    fi
    ```

- Setting up [Crowdsec](https://www.linuxserver.io/blog/blocking-malicious-connections-with-crowdsec-and-swag), [Geoblock](/geoblock/), and [Firehol](/firehol/) is highly recommended.
- After upgrading simplelogin run:

    ```bash
    docker exec slapp alembic upgrade head
    ```

- [Check the dmarc](https://www.learndmarc.com/) once you finish setting everything up.
- [Check the spammyness](https://www.mail-tester.com/) once you finish setting everything up.

## Example Compose


```yaml
  simplelogin:
    image: lscr.io/linuxserver-labs/simplelogin:latest
    container_name: simplelogin
    volumes:
      - ./mail/sl:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - DB_URI=postgresql://dbuser:dbpassword@sldb:5432/simplelogin
    ports:
      - 7777:7777
    restart: unless-stopped
  sldb:
    image: postgres:12.1-alpine
    container_name: sldb
    volumes:
      - ./mail/db:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=dbuser
      - POSTGRES_PASSWORD=dbpassword
      - POSTGRES_DB=simplelogin
    restart: unless-stopped
  postfix:
    container_name: postfix
    image: simplelogin/postfix:4.2.0
    ports:
      - "0.0.0.0:25:25"
      - "0.0.0.0:465:465"
    volumes:
      - ./mail/db:/var/lib/postgresql/data
      - ./swag/etc/letsencrypt:/etc/letsencrypt
      - ./mail/check-cert.sh:/etc/periodic/hourly/renew-postfix-tls:ro
    environment:
      - DB_HOST=sldb
      - DB_USER=dbuser
      - DB_PASSWORD=dbpassword
      - DB_NAME=simplelogin
      - EMAIL_HANDLER_HOST=simplelogin
      - POSTFIX_FQDN=mail.domain.com
      - ALIASES_DEFAULT_DOMAIN=domain.com
      - LETSENCRYPT_EMAIL=support@domain.com
      - TLS_KEY_FILE=/etc/letsencrypt/live/domain.com/privkey.pem
      - TLS_CERT_FILE=/etc/letsencrypt/live/domain.com/fullchain.pem
      - RENEW_PATH=/etc/letsencrypt/postfix_renew
      - POSTFIX_DQN_KEY=dqnkey
      - SIMPLELOGIN_COMPATIBILITY_MODE=v4
    restart: unless-stopped
```

## Example ENV File

```bash
URL=https://simplelogin.domain.com
EMAIL_DOMAIN=domain.com
SUPPORT_EMAIL=support@domain.com
ADMIN_EMAIL=support@domain.com
EMAIL_SERVERS_WITH_PRIORITY=[(10, "mail.domain.com.")]
DKIM_PRIVATE_KEY_PATH=/config/dkim.key
DB_URI=postgresql://dbuser:dbpassword@sldb:5432/simplelogin
FLASK_SECRET=secret123
GNUPGHOME=/config/gnupg
LOCAL_FILE_UPLOAD=1
POSTFIX_SERVER=postfix
DISABLE_ONBOARDING=true
NAMESERVERS="1.1.1.1"
DISABLE_REGISTRATION=0
```

## Self Test

Create `test` aliases for each domain and disable them so you won't get emails.
Add the following to your host's cron, edit the `TARGETS` and `curl` command accordingly.

```bash
#!/bin/bash

TARGETS=("test@domain1.com" "test@domain2.com" "test@domain3.com")

for TARGET in "${TARGETS[@]}"; do
    docker exec postfix sendmail $TARGET
    sleep 10
    result=$(docker exec sldb psql -U sl_user simplelogin -AXqtc "SELECT COUNT(*) FROM email_log JOIN alias ON email_log.alias_id = alias.id WHERE alias.email = '$TARGET' AND email_log.created_at BETWEEN NOW() - INTERVAL '5 MINUTES' AND NOW();")
    if [[ "$result" -lt 1 ]]; then
        curl -d "Email test failed for $TARGET" "https://ntfy.domain1.com/topic"
    fi
done
```