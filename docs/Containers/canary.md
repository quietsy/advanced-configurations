---
tags:
  - Containers
---

# Canary

## Canary Tokens

[Canary tokens](https://www.canarytokens.org/nest/generate) are like motion sensors for your networks, computers and clouds. You can put them in folders, on network devices and on your phones.

Place them where nobody should be poking around and get a clear alarm if they are accessed. They are designed to look juicy to attackers to increase the likelihood that they are opened (and they are completely free).

Examples:

- QR code called wallet.png
- Microsoft Excel called passwords.xlsx
- Microsoft Word called servers.docx
- AWS keys called aws-keys.txt
- Wireguard VPN configuration
- Acrobat Reader PDF called investments.pdf

## Opencanary Honeypot Container

[OpenCanary](https://github.com/thinkst/opencanary) is a multi-protocol network honeypot. It's primary use-case is to catch hackers after they've breached non-public networks. It has extremely low resource requirements and can be tweaked, modified, and extended.

### Config

- Place the config somewhere under `opencanary.conf`.
- Disable or change ports already taken.
- Change the webhook to alert you of attacks.

```json
{
    "device.node_id": "opencanary-server",
    "ip.ignorelist": [  ],
    "logtype.ignorelist": [  ],
    "git.enabled": true,
    "git.port" : 9418,
    "ftp.enabled": true,
    "ftp.port": 21,
    "ftp.banner": "FTP server ready",
    "ftp.log_auth_attempt_initiated": false,
    "http.banner": "Apache/2.2.22 (Ubuntu)",
    "http.enabled": true,
    "http.port": 80,
    "http.skin": "nasLogin",
    "http.skin.list": [
        {
            "desc": "Plain HTML Login",
            "name": "basicLogin"
        },
        {
            "desc": "Synology NAS Login",
            "name": "nasLogin"
        }
    ],
    "http.log_unimplemented_method_requests": false,
    "http.log_redirect_request": false,
    "https.enabled": true,
    "https.port": 443,
    "https.skin": "nasLogin",
    "https.certificate": "/etc/ssl/opencanary/opencanary.pem",
    "https.key": "/etc/ssl/opencanary/opencanary.key",
    "httpproxy.enabled" : true,
    "httpproxy.port": 8080,
    "httpproxy.skin": "squid",
    "httproxy.skin.list": [
        {
            "desc": "Squid",
            "name": "squid"
        },
        {
            "desc": "Microsoft ISA Server Web Proxy",
            "name": "ms-isa"
        }
    ],
    "llmnr.enabled": false,
    "llmnr.query_interval": 60,
    "llmnr.query_splay": 5,
    "llmnr.hostname": "DC03",
    "llmnr.port": 5355,
    "logger": {
        "class": "PyLogger",
        "kwargs": {
            "formatters": {
                "plain": {
                    "format": "%(message)s"
                },
                "syslog_rfc": {
                    "format": "opencanaryd[%(process)-5s:%(thread)d]: %(name)s %(levelname)-5s %(message)s"
                }
            },
            "handlers": {
                "console": {
                    "class": "logging.StreamHandler",
                    "stream": "ext://sys.stdout"
                },
                "Webhook": {
                    "class": "opencanary.logger.WebhookHandler",
                    "url": "https://ntfy.domain.com/topic",
                    "method": "POST",
                    "data": "%(message)s",
                    "status_code": 200,
                    "ignore": ["Added service from class", "Canary running", "startYourEngines"],
                    "headers": {
                        "Title": "OpenCanary"
                    }
                }
            }
        }
    },
    "portscan.enabled": true,
    "portscan.ignore_localhost": false,
    "portscan.logfile":"/var/log/kern.log",
    "portscan.synrate": 5,
    "portscan.nmaposrate": 5,
    "portscan.lorate": 3,
    "portscan.ignore_ports": [ ],
    "smb.auditfile": "/var/log/samba-audit.log",
    "smb.enabled": true,
    "mysql.enabled": true,
    "mysql.port": 3306,
    "mysql.banner": "5.5.43-0ubuntu0.14.04.1",
    "mysql.log_connection_made": false,
    "ssh.enabled": true,
    "ssh.port": 22,
    "ssh.version": "SSH-2.0-OpenSSH_5.1p1 Debian-4",
    "redis.enabled": true,
    "redis.port": 6379,
    "rdp.enabled": true,
    "rdp.port": 3389,
    "sip.enabled": true,
    "sip.port": 5060,
    "snmp.enabled": true,
    "snmp.port": 161,
    "ntp.enabled": true,
    "ntp.port": 123,
    "tftp.enabled": true,
    "tftp.port": 69,
    "tcpbanner.maxnum":10,
    "tcpbanner.enabled": true,
    "tcpbanner_1.enabled": true,
    "tcpbanner_1.port": 8001,
    "tcpbanner_1.datareceivedbanner": "",
    "tcpbanner_1.initbanner": "",
    "tcpbanner_1.alertstring.enabled": false,
    "tcpbanner_1.alertstring": "",
    "tcpbanner_1.keep_alive.enabled": false,
    "tcpbanner_1.keep_alive_secret": "",
    "tcpbanner_1.keep_alive_probes": 11,
    "tcpbanner_1.keep_alive_interval":300,
    "tcpbanner_1.keep_alive_idle": 300,
    "telnet.enabled": true,
    "telnet.port": 23,
    "telnet.banner": "",
    "telnet.honeycreds": [
        {
            "username": "admin",
            "password": "$pbkdf2-sha512$19000$bG1NaY3xvjdGyBlj7N37Xw$dGrmBqqWa1okTCpN3QEmeo9j5DuV2u1EuVFD8Di0GxNiM64To5O/Y66f7UASvnQr8.LCzqTm6awC8Kj/aGKvwA"
        },
        {
            "username": "admin",
            "password": "admin1"
        }
    ],
    "telnet.log_tcp_connection": false,
    "mssql.enabled": true,
    "mssql.version": "2012",
    "mssql.port":1433,
    "vnc.enabled": true,
    "vnc.port":5000
}
```

### Compose

- Remove or change ports already taken.
- Change the path to `opencanary.conf`.

```yaml
  opencanary:
    image: thinkst/opencanary
    container_name: opencanary
    volumes:
      - /path/to/opencanary/opencanary.conf:/root/.opencanary.conf
    ports:
      # FTP
      - "21:21"
      # SSH
      - "22:22"
      # Telnet
      - "23:23"
      # TFTP
      - "69:69"
      # HTTP
      - "80:80"
      # NTP
      - "123:123"
      # SNMP
      - "161:161"
      # HTTPS
      - "443:443"
      # MSSQL
      - "1433:1433"
      # MYSQL
      - "3306:3306"
      # RDP
      - "3389:3389"
      # VNC
      - "5000:5000"
      # SIP
      - "5060:5060"
      # REDIS
      - "6379:6379"
      # TCP Banner
      - "8001:8001"
      # HTTP Proxy
      - "8080:8080"
      # Git
      - "9418:9418"
    restart: unless-stopped
```

