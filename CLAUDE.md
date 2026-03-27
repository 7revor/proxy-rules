# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal proxy rules and network utility scripts collection:
- **Surge Modules**: JavaScript URL redirect scripts for network configuration
- **Traffic Control**: Bash script for P2P bandwidth limiting via Linux `tc`

## Files

### `emby_redirect.js`
Surge script that rewrites Emby request URLs when connected to a specific router (IPv4). Takes 3 comma-separated arguments: `router,source,target`.

### `emby_redirect_ip.js`
Similar to above but uses WiFi SSID instead of router, with tvOS support.

### `tc_p2p.sh`
Linux traffic control script that dynamically limits P2P (qBittorrent) upload bandwidth:
- Monitors upload speed on `eth0`
- Applies HTB qdisc to mark and shape traffic
- Triggers limit when upload exceeds 55 Mbps, recovers when below 15 Mbps
- Uses `fwmark` to classify P2P traffic (class `1:10`)

## Usage

**tc_p2p.sh**: Run as root on Linux router/gateway:
```bash
sudo ./tc_p2p.sh
```

**Surge scripts**: Configure in Surge config with `argument` parameter:
```
[Script]
emby_redirect = type=http-request,pattern=^http://.*\.,script-path=emby_redirect.js,argument=192.168.1.1,emby.example.com,10.0.0.1
```

## Notes

- No build system or package manager - pure JavaScript/Bash
- No tests configured
