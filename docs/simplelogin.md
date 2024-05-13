# Simplelogin

## Notes

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


## Example Compose


```yaml
x-sl: &sl
  # Run after upgrade: docker exec slapp alembic upgrade head
  image: simplelogin/app-ci:v4.43.0
  volumes:
    - ./mail/sl:/sl
    - ./mail/sl/upload:/code/static/upload
    - ./mail/simplelogin.env:/code/.env
    - ./mail/dkim.key:/dkim.key:ro
    - ./mail/dkim.pub.key:/dkim.pub.key:ro
  restart: always
services:
  slapp:
    <<: *sl
    container_name: slapp
  slmail:
    <<: *sl
    container_name: slmail
    command: python email_handler.py
  sljob:
    <<: *sl
    container_name: sljob
    command: python job_runner.py
  sldb:
    image: postgres:12.1-alpine
    container_name: sldb
    volumes:
      - ./mail/db:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=dbuser
      - POSTGRES_PASSWORD=dbpassword
      - POSTGRES_DB=simplelogin
    restart: always
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
      - EMAIL_HANDLER_HOST=slmail
      - POSTFIX_FQDN=mail.domain.com
      - ALIASES_DEFAULT_DOMAIN=domain.com
      - LETSENCRYPT_EMAIL=support@domain.com
      - TLS_KEY_FILE=/etc/letsencrypt/live/domain.com/privkey.pem
      - TLS_CERT_FILE=/etc/letsencrypt/live/domain.com/fullchain.pem
      - RENEW_PATH=/etc/letsencrypt/postfix_renew
      - POSTFIX_DQN_KEY=dqnkey
      - SIMPLELOGIN_COMPATIBILITY_MODE=v4
    restart: always
```

## Example ENV File

```bash
URL=https://simplelogin.domain.com
EMAIL_DOMAIN=domain.com
SUPPORT_EMAIL=support@domain.com
ADMIN_EMAIL=support@domain.com
EMAIL_SERVERS_WITH_PRIORITY=[(10, "mail.domain.com.")]
DKIM_PRIVATE_KEY_PATH=/dkim.key
DB_URI=postgresql://dbuser:dbpassword@sldb:5432/simplelogin
FLASK_SECRET=secret123
GNUPGHOME=/sl/pgp
LOCAL_FILE_UPLOAD=1
POSTFIX_SERVER=postfix
DISABLE_ONBOARDING=true
NAMESERVERS="1.1.1.1"
DISABLE_REGISTRATION=0
```