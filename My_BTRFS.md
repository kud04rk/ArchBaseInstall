# BTRFS:
https://www.youtube.com/watch?v=sm_fuBeaOqE 
at 8 min mark 



# References:
Follow the refernces for your set up and refer here for help
https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Snapshots
https://wiki.archlinux.org/title/btrfs#Snapshots

## Commands:

### format: 
```
mkfs.btrfs -L "ROOT" "/dev/sda2" -f

```
### Creating subvolumes:

These are like folders which act like virtual partitions that can be mounted.(meaning linked(accessed) from that mount point.)

- In ext4 generally to separate the home parition a separate parition is created but in btrfs a subvolume can do the job.

- so, multiple subvolumes for each partition are created 
root subvolume is created at @: btrfs subvolume create /mnt/@
home at @home : btrfs subvolume create /mnt/@home

- Generally these two are sufficient but we can also create:
@var: btrfs subvolume create /mnt/@var
@snapshots btrfs subvolume create /mnt/@snapshots 

- These subvols are then mounted by creating folders in the @
order is important:

These are not acctual commands but referecnes.
You can refer to the actual commands in my sctipt.

### [Disk Setup](https://github.com/smsriharsha/ArchBaseInstall/blob/main/1_disksetup.sh)

https://github.com/smsriharsha/ArchBaseInstall/blob/main/1_disksetup.sh

# Note 
The below are not accutal commands.

```
mount -o noatime,compress=lzo,space_cache,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{boot,home,var,.snapshots}
mount -o noatime,compress=lzo,space_cache,subvol=@home /dev/sda2 /mnt/home
mount -o noatime,compress=lzo,space_cache,subvol=@var /dev/sda2 /mnt/var
mount -o noatime,compress=lzo,space_cache,subvol=@snapshots /dev/sda2 /mnt/.snapshots
```

note boot cannot be btrfs (only fat32)


## Mini Desc
- Better file system

- Similar to ext 4 we just format partition in btrfs

- generally only one partition is created.

- but multiple can be created.