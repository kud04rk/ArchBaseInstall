# ArchBaseInstall
 Arch linux base install script.
  NOTE: SYSTEMD BOOT DOESNT WORK.AMD GPU NOT TESTED
  Tested With only integrated gpu and nvidia gpu.

 This script is used to install the base package of the linux system with btrfs file system.
 
 CHANGE THE LANGUGE AND LOCALES BEFORE USING THE SCRIPT
 
 After the install of the script you can continue with the installation of desktop environment or window manager.
 


## Check if the wifi devices are blocked.
```
rfkill list
```
## Turn Them on.
```
rfkill unblock all
```

## Connect To wifi
```
device list

#device is name of device(ex: wlan0)

station device scan
station device get-networks
station device connect SSID
```
## References For help
https://wiki.archlinux.org/title/Network_configuration/Wireless

https://wiki.archlinux.org/title/Iwd
