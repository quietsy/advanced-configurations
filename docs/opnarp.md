# OPN-Arp

OPN-Arp on OPNSense allows you to send alerts when new devices are spotted on the network.

![opnarp](images/opnarp.png)

## Setup

- Install the `opn-arp` plugin via the [community repo](https://www.routerperformance.net/opnsense-repo/)
- Enable OPN-Arp under Services > OPN-Arp
- Enable Monit under Services > Monit
- Add a new entry under Service Tests Settings:
  - Name: `MAC pair`
  - Condition: `content = "MAC pair"`
  - Action: `Alert` for an email alert or `/root/gotify.sh` for gotify (script below)
- Add a new entry under Service Settings:
  - Name: `MAC_PAIR`
  - Type: `File`
  - Path: `/var/log/system/latest.log`
  - Tests: `MAC Pair`
- Add a new entry under Alert Settings: (only for email alerts)
  - Recipient: `your@email.com`
  - Mail Format: `From: your@email.com`
- Fill the mail server details under general (only for email alerts)

## Gotify Alerts

- Connect to OPNSense via SSH
- Execute `touch /root/gotify.sh && chmod +x /root/gotify.sh`
- Paste the following script:

    ```bash
    #!/usr/local/bin/bash

    if [[ $MONIT_DESCRIPTION =~ "MAC pair" ]]; then
            ip=$(echo $MONIT_DESCRIPTION | cut -d '(' -f 2  | cut -d ')' -f 1)
            mac=$(echo $MONIT_DESCRIPTION | cut -d '(' -f 2  | cut -d ')' -f 2)
            host=$(host $ip | cut -d ' ' -f 5)
            title="New device spotted"
            msg="IP: $ip - MAC: $mac - Hostname: $host"
    else
            title=$MONIT_SERVICE
            msg=$MONIT_DESCRIPTION
    fi

    curl -X POST "https://gotify.domain.com/message?token=yourtoken" -F "title=$title" -F "message=$msg"
    ```

- Edit `gotify.domain.com` and `yourtoken` accordingly