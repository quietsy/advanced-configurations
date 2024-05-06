# Hardcoded DNS

Smart home IoT devices are often configured with hardcoded DNS servers such as Google public DNS. 98% of smart assistants and 72% of smart TVs use hardcoded Google DNS servers to resolve DNS queries instead of using the default DNS server configured at the home gateway.

Detailed in the paper [Characterizing Smart Home IoT Traffic in the Wild](https://arxiv.org/pdf/2001.08288.pdf).

Hardcoded DNS can be prevented with the following actions:

- Catch all network traffic on ports 53, 853 and NAT it back to the local DNS.
- Block all traffic to public DoH IPs using [DoH-IP-blocklists](https://github.com/dibdot/DoH-IP-blocklists).
- Block all public DoH domains using [DoH-IP-blocklists](https://github.com/dibdot/DoH-IP-blocklists).

The following rules were made using OPNSense and AdGuardHome to achieve it.

## OPNSense

### Alias

Navigate to Firewall > Aliases and create the following aliases:

```
Name: NAT_Ports
Type: Ports
Content: 53, 853
```

```
Name: Internal
Type: Networks
Content: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
```

```
Name: Public_DNS
Type: URL IPs
Content: https://raw.githubusercontent.com/dibdot/DoH-IP-blocklists/master/doh-ipv4.txt, https://raw.githubusercontent.com/dibdot/DoH-IP-blocklists/master/doh-ipv6.txt
```

### NAT

The NAT rule redirects all traffic on ports 53, 853 to the local DNS.

Navigate to Firewall > NAT > Port Forward and create the following NAT rule:

```
Interface: Select all the LAN and VLAN interfaces
Protocol: TCP/UDP
Source: Internal (the alias we created)
Destination / Invert: checked
Destination: This Firewall (the local DNS, in my case AGH runs on opnsense)
Destination port range: NAT_Ports (the alias we created)
Redirect target IP: 192.168.0.1 (the local DNS IP, in my case AGH runs on opnsense)
Redirect target port: NAT_Ports
```

### Floating

The floating rule blocks DoH traffic.

Navigate to Firewall > Rules > Floating and create the following floating rule:

```
Action: Block
Interface: Select all the interfaces
Direction: any
TCP/IP Version: IPv4+IPv6
Protocol: TCP/UDP
Source / Invert: checked
Source: This Firewall (the local DNS, in my case AGH runs on opnsense)
Destination: Public_DNS (the alias we created)
Destination port range: HTTPS
```

### AdGuardHome

The AdGuardHome blocklist blocks DoH domains.

Navigate to AGH > Filters > DNS blocklists and add the following blocklist:

```
https://raw.githubusercontent.com/dibdot/DoH-IP-blocklists/master/doh-domains.txt
```

### Cron

Create a cron job to automatically update the blocklist every day.

Navigate to System > Settings > Cron and add the following job:

```
Eabled: checked
Minutes: 0
Hours: 0
Day of the month: *
Months: *
Days of the week: *
Command: Update and reload firewall aliases
```
