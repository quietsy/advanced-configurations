# Smartd

`smartd` is a daemon that monitors the Self-Monitoring, Analysis and Reporting Technology (SMART) system built into many ATA-3 and later ATA, IDE and SCSI-3 hard drives. The purpose of SMART is to monitor the reliability of the hard drive and predict drive failures, and to carry out different types of drive self-tests.

## Installation

```bash
sudo apt install smartmontools
```

## Configuration

Add the following to `/etc/smartmontools/smartd.conf`:

```
DEVICESCAN -a -S on -s (S/../.././03|L/../01/./02) -W 10,50,60 -m <nomailer> -M exec /home/user/ntfy.sh -M test
```

- `-a` - Equivalent to turning on all of the following Directives: '-H' to check the SMART health status, '-f' to report failures of Usage (rather than Prefail) Attributes, '-t' to track changes in both Prefailure and Usage Attributes, '-l error' to report increases in the number of ATA errors, '-l selftest' to report increases in the number of Self-Test Log errors, '-l selfteststs' to report changes of Self-Test execution status, '-C 197' to report nonzero values of the current pending sector count, and '-U 198' to report nonzero values of the offline pending sector count.
- `-S on` - Enables or disables Attribute Autosave when smartd starts up and has no further effect.
- `-s` - Run Self-Tests or Offline Immediate Tests, at scheduled times.
- `S/../.././03` - Runs a short test daily at 3AM.
- `L/../01/./02` - Runs a long test on the first of every month at 2AM.
- `-W 10,50,60` - Tracks disk temperatures and alerts if they rise too quickly or hit a high limit. The following will log changes of 10 degrees or more, log when temp reaches 50 degrees, and log/email a warning when temp reaches 60.
- `-m <nomailer> -M exec /home/user/ntfy.sh` - Run a shell script instead of the default mail command for alerts.
- `-M test` - Test the notification script, remove after testing.

Add the following to `/home/user/ntfy.sh`, replace the domain and topic:

```bash
#!/bin/bash

/usr/bin/curl -Ls -H "Title: $SMARTD_SUBJECT" -d "$SMARTD_FAILTYPE Device: $SMARTD_DEVICE Time: $SMARTD_TFIRST Message: $SMARTD_FULLMESSAGE" https://ntfy.domain.com/Topic
```

Restart to test the alert:

```bash
chmod +x /home/user/ntfy.sh
sudo systemctl restart smartd
```

Remove ` -M test` from `smartd.conf` if everything works, and restart `smartd` again.
