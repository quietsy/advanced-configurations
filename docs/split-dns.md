# Split DNS

A split DNS allows you to rewrite DNS requests from `*.domain.com` directly to your server instead of having to go through the router, it has several benefits:

- Everything is faster due to not having to go through the router
- Can easily differentiate between internal and external requests with [geoblock](/secure/#geoblock) and [allow/deny](/secure/#internal-applications)
- Everything still works when the internet is down
- Everything still works when the upstream DNS isn't available

![Split DNS](images/split_dns_nat_reflection.png)


## Requirements

- A working internal reverse proxy listening to port 443
- A valid domain pointing to the reverse proxy with a wildcard SSL certificate
- An internal DNS that supports rewrites

## Popular DNS Configurations

These examples assume `domain.com` is your domain and `10.10.10.10` is your reverse proxy.

### OPNSense

Navigate to Services > Unbound DNS > Overrides > Host Overrides > Add

- Host: `*`
- Domain: `domain.com`
- Type: `A or AAAA`
- IP: `10.10.10.10`

### PFSense

Navigate to Services > DNS Resolver > General Setting > Host Overrides > Add

- Host: `*`
- Domain: `domain.com`
- IP Address: `10.10.10.10`

### Pihole & dnsmasq

Create a file called `/etc/dnsmasq.d/domain.conf` with this contents:

```
address=/domain.com/10.10.10.10
```

### Adguard

Navigate to Filters > DNS rewrites > Add DNS rewrite

- Domain name: `*.domain.com`
- IP Address: `10.10.10.10`
