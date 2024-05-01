# Wireguard Hub
![Hub](images/hub.png)

Linuxserver's Wireguard container is extremely versatile, in this example we'll use it as a server that tunnels clients through multiple redundant vpn connections while maintaining access to the LAN.

VPN providers have a limit on the amount of devices, this setup will allow you to have an unlimited amount of devices tunneled through a single VPN connection while also supporting a failover backup connection!

## Requirements

- A working instance of our [Wireguard container](https://github.com/linuxserver/docker-wireguard) in server mode.

## Initial Wireguard Server Configuration

Configure a standard Wireguard server according to the [Wireguard documentation](https://github.com/linuxserver/docker-wireguard).

```YAML
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - SERVERURL=wireguard.domain.com
      - SERVERPORT=51820
      - PEERS=1
      - PEERDNS=auto
      - INTERNAL_SUBNET=10.13.13.0
    volumes:
      - /path/to/appdata/config:/config
      - /lib/modules:/lib/modules
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
```

Start the container and validate that `docker logs wireguard` contains no errors (Ignore the missing wg0.conf message), and validate that the server is working properly by connecting a client to it.

## VPN Client Tunnels Configuration

Copy the 2 Wireguard configs that you get from your VPN providers into files under `/config/wg_confs/wg1.conf` and `/config/wg_confs/wg2.conf`.

### Example wg1.conf

Make the following changes:

- Add `Table = 55111` to distinguish rules for this interface.
- Add `PostUp` and `PreDown` rules to nat and firewall the traffic.
- Add `PersistentKeepalive = 25` to keep the tunnel alive.
- Make sure you're using the `PrivateKey`, `Address`, `PublicKey`, and `Endpoint` that you got from your VPN provider (below is just an example).

```ini
[Interface]
PrivateKey = ...
Address = 10.65.156.233/32
Table = 55111

PostUp = iptables -I FORWARD -i wg0 -o %i -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o %i -j MASQUERADE
PostUp = ip rule add pref 10000 from 10.13.13.0/24 lookup 55111
PreDown = ip rule del from 10.13.13.0/24 lookup 55111
PreDown = iptables -t nat -D POSTROUTING -o %i -j MASQUERADE
PreDown = iptables -D FORWARD -i wg0 -o %i -j ACCEPT

[Peer]
PublicKey = ...
AllowedIPs = 0.0.0.0/0
Endpoint = 169.150.217.215:51820
PersistentKeepalive = 25
```

### Example wg2.conf

Make the following changes:

- Add `Table = 55112` to distinguish rules for this interface.
- Add `PostUp` and `PreDown` rules to nat and firewall the traffic.
- Add `PersistentKeepalive = 25` to keep the tunnel alive.
- Make sure you're using the `PrivateKey`, `Address`, `PublicKey`, and `Endpoint` that you got from your VPN provider (below is just an example).

```ini
[Interface]
PrivateKey = ...
Address = 10.67.126.217/32
Table = 55112

PostUp = iptables -I FORWARD -i wg0 -o %i -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o %i -j MASQUERADE
PostUp = ip rule add pref 10000 from 10.13.13.0/24 lookup 55112
PreDown = ip rule del from 10.13.13.0/24 lookup 55112
PreDown = iptables -t nat -D POSTROUTING -o %i -j MASQUERADE
PreDown = iptables -D FORWARD -i wg0 -o %i -j ACCEPT

[Peer]
PublicKey = ...
AllowedIPs = 0.0.0.0/0
Endpoint = 169.150.217.232:51820
PersistentKeepalive = 25
```

Save the changes and restart the container with `docker restart wireguard`, validate that `docker logs wireguard` contains no errors.

Perform the following validations to check that the VPN tunnels works:

- Check that you have connectivity on wg1 by running `docker exec wireguard ping -c4 -I wg1 1.1.1.1`.
- Check that you have connectivity on wg2 by running `docker exec wireguard ping -c4 -I wg2 1.1.1.1`.
- Check the details of your VPN tunnel on wg1 by running `docker exec wireguard curl --interface wg1 -s https://am.i.mullvad.net/json`, you should get an IP that is different from your WAN IP.
- Check the details of your VPN tunnel on wg2 by running `docker exec wireguard curl --interface wg2 -s https://am.i.mullvad.net/json`, you should get an IP that is different from your WAN IP.

## Failover Script

Place the following failover script under `/config/wg_failover.sh`, the defaults match the examples but you can read the comments explaining each parameter and modify them.

```Bash
#!/bin/bash

# Ping targets to check connectivity, the default is cloudflare and google DNS addresses
TARGETS=("1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4")
# How many failed pings are allowed before failover
FAILOVER_LIMIT=2
# The subnets that should be tunneled through wireguard
LOCAL_RANGES=("10.13.13.0/24")
# An array of tunnel details corresponding to the tunnel conf: <tunnel-name>;<table-number>;<rule-priority>
TUNNELS=("wg1;55111;10000" "wg2;55112;10000")
# Connectivity check interval in seconds
PING_INTERVAL=20
LOG_FILE="/config/wg_failover.log"

apply_rules () {
	for LOCAL_RANGE in "${LOCAL_RANGES[@]}"
	do
		ip rule del from ${LOCAL_RANGE} lookup $1
		ip rule add pref $2 from ${LOCAL_RANGE} lookup $1
	done
}

FAILED=()
INDEX=0
while sleep $PING_INTERVAL
do
	COUNTER=1
	IFS=";" read -r -a TUNNEL <<< "${TUNNELS[INDEX]}"
	TUNNEL_NAME="${TUNNEL[0]}"
	TUNNEL_TABLE=${TUNNEL[1]}
	TUNNEL_PRIORITY=${TUNNEL[2]}
	wg-quick up "${TUNNEL_NAME}" > /dev/null 2>&1

	for TARGET in "${TARGETS[@]}"
	do
		if ! ping -c1 -w10 -I "${TUNNEL_NAME}" "${TARGET}" > /dev/null 2>&1; then
		  (( COUNTER++ ))
		fi
	done
	if [[ "$COUNTER" -gt "$FAILOVER_LIMIT" ]] && [[ ! "${FAILED[*]}" =~ "${TUNNEL_NAME}" ]]; then
		echo "$(date +'%Y-%m-%d %T') - ${TUNNEL_NAME} failed ${COUNTER} pings" >> $LOG_FILE
		apply_rules "${TUNNEL_TABLE}" "$(( TUNNEL_PRIORITY+1000 ))"
		FAILED+=(${TUNNEL_NAME})
	elif [[ "$COUNTER" -le "$FAILOVER_LIMIT" ]] && [[ "${FAILED[*]}" =~ "${TUNNEL_NAME}" ]]; then
		echo "$(date +'%Y-%m-%d %T') - ${TUNNEL_NAME} restored" >> $LOG_FILE
		apply_rules "${TUNNEL_TABLE}" "$(( TUNNEL_PRIORITY ))"
		FAILED=( "${FAILED[@]/$TUNNEL_NAME}" )
	elif [[ "$COUNTER" -gt "$FAILOVER_LIMIT" ]] && [[ "${FAILED[*]}" =~ "${TUNNEL_NAME}" ]]; then
		wg-quick down "${TUNNEL_NAME}" > /dev/null 2>&1
	fi
	(( INDEX++ ))
	if [[ $INDEX+1 > ${#TUNNELS[@]} ]]; then
		INDEX=0
	fi
done

```

## Wireguard Server Configuration Changes

Edit `/config/templates/server.conf`, replace the PostUp/PreDown rules with the rules listed below, these rules are required for the server to forward traffic to the VPN client tunnels and activate the fail-over script.

Replace `192.168.10.0/24` with your LAN subnet.

```ini
PostUp = ip rule add pref 100 to 10.13.13.0/24 lookup main
PostUp = ip rule add pref 100 to 192.168.10.0/24 lookup main
PostUp = iptables -I FORWARD -i %i -d 10.0.0.0/8 -j ACCEPT
PostUp = iptables -I FORWARD -i %i -d 172.16.0.0/12 -j ACCEPT
PostUp = iptables -I FORWARD -i %i -d 192.168.0.0/16 -j ACCEPT
PostUp = iptables -I FORWARD -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT
PostUp = iptables -A FORWARD -j REJECT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostUp = /config/wg_failover.sh &
PreDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PreDown = iptables -D FORWARD -j REJECT
PreDown = iptables -D FORWARD -o %i -m state --state RELATED,ESTABLISHED -j ACCEPT
PreDown = iptables -D FORWARD -i %i -d 10.0.0.0/8 -j ACCEPT
PreDown = iptables -D FORWARD -i %i -d 172.16.0.0/12 -j ACCEPT
PreDown = iptables -D FORWARD -i %i -d 192.168.0.0/16 -j ACCEPT
PreDown = ip rule del to 10.13.13.0/24 lookup main
PreDown = ip rule del to 192.168.10.0/24 lookup main
```

Save the changes and delete `/config/wg_confs/wg0.conf` so it would be generated again, restart the container with `docker restart wireguard`, validate that `docker logs wireguard` contains no errors.

Try navigating to `https://am.i.mullvad.net/json` on one of your client devices and verify that the Wireguard server is working properly and that you're tunneled through one the VPN tunnels.

## Excluding Sites from the VPN

Some sites block VPNs, so we can exclude the IPs of these sites from the VPN tunnels.

Add the following environment variables to wireguard's compose for installing the ipset package:

```yaml
      - DOCKER_MODS=linuxserver/mods:universal-package-install
      - INSTALL_PACKAGES=ipset
```

Create a text file under `/config/domains.txt` for the domains we want to exclude, such as:

```
site.net
othersite.com
moresites.org
```

Create a shell script under `/config/domains.sh` for resolving the IPs of domains and adding them to the ipset:

```bash
#!/bin/bash

DOMAINS=$(cat "/config/domains.txt")

for DOMAIN in $DOMAINS
do
    if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        IPS=($DOMAIN)
    else
        IPS=$(nslookup $DOMAIN | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | grep -v "127.0.0.")
    fi
    

    for IP in $IPS
    do
        echo "Rerouting $DOMAIN $IP"
        ipset -exist add domains $IP
    done
done
```

Create a shell script under `/config/watch_domains.sh` for watching the domains text file and reloading the ipset on changes:

```bash
#!/bin/bash
 
DIR_TO_WATCH="/config/domains.txt"
COMMAND="/config/domains.sh"
$COMMAND
trap "echo Exited!; exit;" SIGINT SIGTERM > /dev/null 2>&1
while [[ 1=1 ]]
do
    watch --chgexit -n 1 "ls --all -l --recursive --full-time ${DIR_TO_WATCH} | sha256sum" && ${COMMAND}
    sleep 1
done
```

Add the following to `/config/templates/server.conf`:

```ini
PostUp = ipset -exist create domains hash:net
PostUp = iptables -t mangle -A PREROUTING -m set --match-set domains dst -j MARK --set-mark 6
PostUp = iptables -I FORWARD 1 -i %i -m set --match-set domains dst -j ACCEPT
PostUp = ip rule add pref 5000 fwmark 6 lookup main
PostUp = /config/watch_domains.sh &
PreDown = ip rule del fwmark 6 lookup main
PreDown = ipset destroy domains
PreDown = iptables -t mangle -D PREROUTING -m set --match-set domains dst -j MARK --set-mark 6
PreDown = iptables -D FORWARD -i %i -m set --match-set domains dst -j ACCEPT
```

These rules route all IPs associated with the domains directly, bypassing the VPN.

### Frontend for Excluding

You can host a simple PHP web page for adding domains to `domains.txt` on any web server like SWAG.

Mount `domains.txt` on both the web server and on the wireguard hub container.

```html
<!DOCTYPE html> 
<html> 
<head> 
  <title>Unblock</title> 
</head> 
<body> 
 
<form method="post"> 
  <input type="text" name="URL" id="URL"> 
  <button type="submit" name="Unblock">Unblock</button> 
</form> 
 
<?php 
if(isset($_POST['Unblock'])) { 
	$url = $_POST['URL'];
	$file = 'domains.txt';
	$parsed = parse_url($url, PHP_URL_HOST) ?: $url;
	$current = file_get_contents($file);
	if (str_contains($current, $parsed)) {
		echo $parsed.' is already unblocked';
	} else {
		file_put_contents($file, PHP_EOL.$parsed, FILE_APPEND | LOCK_EX);
		echo 'Unblocked '.$parsed;
	}
} 
?> 
 
</body> 
</html> 
```


## Traffic Overview

![Hub3](images/hub2.png)

The order of traffic is as follows:

1. Localhost - traffic to the container.
2. Local network - traffic the DNS and gateway.
3. Wireguard clients - traffic to the wireguard clients.
4. Excluded domains - bypasses the VPN and routes directly.
5. Main VPN tunnel - the VPN tunnel in `wg1.conf`.
6. Failover VPN tunnel - the VPN tunnel in `wg2.conf`.