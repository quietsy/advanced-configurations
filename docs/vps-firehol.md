# VPS Firehol Blocklists

Firehol blocklists are a collection of automatically updating ipsets from all available security IP Feeds, mainly related to on-line attacks, on-line service abuse, malwares, botnets, command and control servers and other cybercrime activities.

## Installation

Install the following packages:

```bash
sudo apt install ipset iprange
```

## Firehol Blocklists

Navigate to [Firehol's website](https://iplists.firehol.org/) or [Firehol's github repo](https://github.com/firehol/blocklist-ipsets) and choose which blocklists you want to enable.

Copy the raw links into `/home/user/firehol/firehol.conf`.
For example:

```
https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset
https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset
https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level3.netset
https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_abusers_1d.netset
```

## Firehol Script

Create a script to refresh the firehol ipsets and recreate the iptables rules.

For example `/home/user/firehol/firehol.sh`:

```bash
#!/bin/bash

LOG="/home/user/firehol/firehol.log"
URLS=$(cat "/home/user/firehol/firehol.conf")
echo "Updating Firehol $(date)" >> $LOG

for URL in $URLS
do
	echo $URL >> $LOG
	NAME=$(basename $URL)
	echo $NAME >> $LOG
	FILE="/home/user/firehol/$NAME"
	curl -s -k $URL > $FILE
	# The following sed removes LAN ranges from the lists, you might block yourself if you remove it
	sed -i -e 's#10.0.0.0/8##' -e 's#172.16.0.0/12##' -e 's#192.168.0.0/16##' -e 's#127.0.0.0/8##' $FILE
	COUNT=$(/usr/bin/iprange -C $FILE)
	COUNT=${COUNT/*,/}
	echo $COUNT >> $LOG
	/usr/sbin/ipset -exist create $NAME hash:net >> $LOG
	/usr/sbin/ipset flush $NAME >> $LOG
	/usr/bin/iprange $FILE --ipset-reduce 20 --ipset-reduce-entries 65535 --print-prefix "-A $NAME " > $FILE.ipset
	/usr/sbin/ipset restore --exist --file $FILE.ipset >> $LOG
	/usr/sbin/iptables -D FORWARD -m set --match-set $NAME src -j DROP &>/dev/null
	/usr/sbin/iptables -D INPUT -m set --match-set $NAME src -j DROP &>/dev/null
	/usr/sbin/iptables -D DOCKER-USER -m set --match-set $NAME src -j DROP &>/dev/null
	/usr/sbin/iptables -I DOCKER-USER 1 -m set --match-set $NAME src -j DROP >> $LOG
	/usr/sbin/iptables -I INPUT 1 -m set --match-set $NAME src -j DROP >> $LOG
	/usr/sbin/iptables -I FORWARD 1 -m set --match-set $NAME src -j DROP >> $LOG
done
```

Verify that it works and the ipsets have been filled:

```bash
chmod +x /home/user/firehol/firehol.sh
sudo /home/user/firehol/firehol.sh
sudo ipset list firehol_level1.netset
```


## Cron Scheduling

### **Warning - make sure you're not accidentally blocking your own access to the VPS before proceeding.**

Run the firehol script on reboot and daily.

For example, add the following to `sudo crontab -e`:

```
0 1 * * * /home/user/firehol/firehol.sh
@reboot sleep 20 && /home/user/firehol/firehol.sh
```

Verify that it runs on reboot and daily.
