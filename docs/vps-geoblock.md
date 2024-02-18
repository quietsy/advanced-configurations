# VPS Geoblock

I've been dealing with constant attacks on a mail server on a VPS coming from 2 specific countries, the only solution that worked was completely blocking these countries.

There are 2 popular geoblock providers, Maxmind and DP-IP, we can utilize them using a python library called [geoipsets](https://github.com/chr0mag/geoipsets).


## Installation

Install the following packages:

```bash
sudo apt install python3 python3.12 python3-pip python3-venv ipset
```

Create a python virtual environment:

```bash
python3 -m venv .venv
```

Verify that it works:

```bash
source .venv/bin/activate
```


## Geoblock Config

Create a geoblock config according to the geoipsets documentation.

For example `/home/user/geoipsets.conf`:

```ini
[general]
provider=dbip
firewall=iptables
address-family=ipv4,ipv6

[countries]
RU
CN
```

Verify that it works:

```bash
source .venv/bin/activate
geoipsets -o /home/user -c /home/user/geoipsets.conf
```


## Geoblock Script

Create a script to refresh the geoblock ipsets and recreate the iptables rules.

For example `/home/user/geoblock.sh`:

```bash
#!/bin/bash

output_path="/home/user"
venv_path="/home/user/.venv/bin/activate"
config_path="/home/user/geoipsets.conf"
log="/home/user/geoblock.log"

echo "Updating Blocklist $(date)" >> $log
source $venv_path
geoipsets -o $output_path -c $config_path >> $log

for i in $(find "${output_path}/geoipsets" -name "*.ipv*");
do
	name=$(basename $i)
	echo $name >> $log
	/usr/sbin/ipset flush $name >> $log
	/usr/sbin/ipset restore --exist --file $i >> $log
	command=$(if [[ $name == *ipv4 ]]; then echo "/usr/sbin/iptables"; else echo "/usr/sbin/ip6tables"; fi)
	$command -D FORWARD -m set --match-set $name src -j DROP &>/dev/null
	$command -D INPUT -m set --match-set $name src -j DROP &>/dev/null
	$command -I INPUT 1 -m set --match-set $name src -j DROP >> $log
	$command -I FORWARD 1 -m set --match-set $name src -j DROP >> $log
done
```

Verify that it works and the ipsets have been filled:

```bash
sudo /home/user/geoblock.sh
sudo ipset list RU.ipv4
```


## Cron Scheduling

Run the geoblock script on reboot and weekly.

For example, add the following to `sudo crontab -e`:

```
20 0 * * 2 /home/user/geoblock.sh
@reboot sleep 20 && /home/user/geoblock.sh
```

Verify that it runs on reboot and weekly.
