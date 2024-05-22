# ZFS

The following creates a zfs pool with 2 mirrors of 2 disks each, with:

- LZ4 compression
- Linux ACLs
- Larger record size for media
- Snapshots with a retention policy:
  - 4 every 15 minutes in the last hour
  - 24 every hour in the last day
  - 31 every day in the last month
  - 8 every week in the last 2 months
  - 12 every month in the last year (disabled for `/mnt/pool/media`)
- Scrub reports and alerts sent to ntfy

## Installation

```bash
sudo apt install zfsutils-linux zfs-auto-snapshot
```

## Creation

Find the IDs of the disks you want to use for the zfs pool:

```bash
sudo lsblk -o NAME,SIZE,SERIAL,LABEL,FSTYPE
NAME          SIZE SERIAL          LABEL FSTYPE
sda          18.2T 8LG7V8BA
sdb          14.6T 2CGREXTB
sdc          18.2T 8LG87T5A
sdd          14.6T 2CGPPSGB
```

Decide on a layout create the zfs pool using the disk IDs:

```bash
sudo mkdir -p /mnt/pool
sudo zpool create -m /mnt/pool pool mirror /dev/disk/by-id/ata-WDC_WUH722020BLE6L4_8LG7V8BA /dev/disk/by-id/ata-WDC_WUH722020BLE6L4_8LG87T5A mirror /dev/disk/by-id/ata-WDC_WUH721816ALE6L4_2CGREXTB /dev/disk/by-id/ata-WDC_WUH721816ALE6L4_2CGPPSGB
```

## Configuration

Set the pool configuration:

```bash
sudo zfs set compression=lz4 pool
sudo zfs set acltype=posixacl pool
sudo zfs set xattr=sa pool
sudo zfs set aclinherit=passthrough pool
sudo zfs set atime=off pool
```

Create a filesystem under `/mnt/pool/media` to configure it for media (larger record size and no monthly snapshots):

```bash
sudo zfs create pool/media
sudo zfs set recordsize=1M pool/media
sudo zfs set com.sun:auto-snapshot:monthly=false pool/media
```

## Alerts

Pull the latest zed scripts that have ntfy support:

```bash
cd /etc/zfs/zed.d/
sudo mv /etc/zfs/zed.d/zed-functions.sh /etc/zfs/zed.d/zed-functions.sh.bak
sudo mv /etc/zfs/zed.d/zed.rc /etc/zfs/zed.d/zed.rc.bak
sudo wget https://raw.githubusercontent.com/openzfs/zfs/master/cmd/zed/zed.d/zed-functions.sh
sudo wget https://raw.githubusercontent.com/openzfs/zfs/master/cmd/zed/zed.d/zed.rc
sudo chmod 0644 /etc/zfs/zed.d/zed-functions.sh
sudo chmod 0600 /etc/zfs/zed.d/zed.rc
```

Edit `/etc/zfs/zed.d/zed.rc` and set the following:

```
ZED_NOTIFY_VERBOSE=1
ZED_NTFY_TOPIC="zfs"
ZED_NTFY_URL="https://ntfy.domain.com"
```

Restart zed:

```bash
sudo systemctl daemon-reload
sudo systemctl restart zed
```

Test the alerts:

```bash
cd /tmp
dd if=/dev/zero of=sparse_file bs=1 count=0 seek=512M
zpool create test /tmp/sparse_file
zpool scrub test
```

Remove the test file:

```bash
zpool export test
rm sparse_file
```