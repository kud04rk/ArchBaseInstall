#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log.out 2>&1
bash 1_disksetup.sh
arch-chroot /mnt /root/ArchBaseInstall/2_setup.sh