# Periodic Phone Wipe Notes

I got into the habit of wiping my phone every 6 months (takes about an hour) in order to:

- Streamline the process
- Validate the backups
- Re-examine which apps should stay
- Remove leftover data
- Figure out the pains and find alternatives

My phone is Poco X3 NFC with [lineage + micro-g](https://lineage.microg.org/), it has an [always-on mullvad + home VPN](/split/), and a lot of self-hosting related apps. 

The main feature of this setup is great idle battery consumption with [up to 7 days on a single charge](https://files.virtualize.link/pics/microg.png).

## Backup

- Snapshot
  - Homepages
  - Toggles
  - App drawer
- Export
  - Wireguard
  - Aegis
  - Gadgetbridge
- Backup the entire phone to the PC

## Install

- Enable USB debugging on the phone
- Get adb working on your PC, on ubuntu for example:
  - Download [android platform tools](https://developer.android.com/studio/releases/platform-tools)
  - Install udev rules `sudo apt install android-sdk-platform-tools-common`
  - Reload udev rules `sudo udevadm control --reload-rules`
  - Add the user to the group ``sudo usermod -a -G plugdev `whoami` ``
  - Logout & login or reboot
  - Check that adb works (`adb devices`)
- Remove fingerprint and pattern
- Download
  - OS & recovery - I use [lineage + micro-g](https://lineage.microg.org/)
  - Firmware - the latest official
- Reboot to bootloader (`adb reboot bootloader`)
- Install recovery (`fastboot flash recovery recovery.img`)
- Reboot to recovery (`fastboot reboot recovery`)
- Format data and cache from recovery
- Install firmware (`adb sideload firmware.zip`)
- Install OS (`adb sideload os.zip`)
- Reboot to OS (`fastboot reboot`)

## Configuration

- Copy exports and snapshots back
- Initial configuration
- Apps
  - Aegis (2FA)
  - Audiobookshelf
  - Aurora store (anonymized play store)
  - Bitwarden (password manager)
  - Davx5 (sync contacts)
  - Discord
  - F-droid (foss app store)
  - Gadgetbridge (cloudless gadgets)
  - Gcam
  - Gelli (music)
  - Gotify (server notifications)
  - Jellyfin (media)
  - LibreTube (youtube)
  - Microsoft lens (scan documents)
  - Mull (browser)
  - Nextcloud (self-hosted cloud)
  - Nextcloud news (rss reader)
  - Nextcloud notes
  - Nextcloud phonetrack (track phone)
  - Proton calendar
  - Protonmail
  - Termux
  - SimpleLogin
  - VLC
  - Waze (navigation)
  - Wireguard (vpn)
- Configure all apps
- Set folders to auto upload to [nextcloud](/nextcloud/)
  - Photos
  - Videos
  - Call recordings
  - Lens documents (auto upload to paperless-ngx)