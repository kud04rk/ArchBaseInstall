
#!/usr/bin/env bash
#-----------------------------------------------------------------------
#   █████████                                            █████         
#  ███░░░░░███                                          ░░███          
# ███     ░░░  ████████  █████ ████  █████   ██████   ███████   ██████ 
#░███         ░░███░░███░░███ ░███  ███░░   ███░░███ ███░░███  ███░░███
#░███          ░███ ░░░  ░███ ░███ ░░█████ ░███████ ░███ ░███ ░███ ░███
#░░███     ███ ░███      ░███ ░███  ░░░░███░███░░░  ░███ ░███ ░███ ░███
# ░░█████████  █████     ░░████████ ██████ ░░██████ ░░████████░░██████ 
#  ░░░░░░░░░  ░░░░░       ░░░░░░░░ ░░░░░░   ░░░░░░   ░░░░░░░░  ░░░░░░  
#-------------------------------------------------------------------------
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "-------------------------------------------------"
echo "-------Ranking best mirrors for Arch----------------"
echo "-------------------------------------------------"
timedatectl set-ntp true
pacman -Sy --noconfirm
pacman -S pacman-contrib --noconfirm
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
echo "-------------------------------------------------"
echo "-------select your disk to install----------------"
echo "-------------------------------------------------"
echo "*******THE SELECTED DISK WILL BE FORMATED********"
lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read DISK
read -p "are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in

y|Y|yes|Yes|YES)
echo "--------------------------------------"
echo -e "\nFormatting disk...\n$HR"
echo "--------------------------------------"

# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
echo "****Please enter the size(MB) of SWAP file****"
read swapsize

sgdisk -n 1::+1024M --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK} # partition 1 (UEFI Boot Partition)
sgdisk -n 2::+${swapsize} --typecode=2:8200 --change-name=2:'SWAP' ${DISK} # partition 2 (swap), default start, remaining
sgdisk -n 3::-0 --typecode=2:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining


# make filesystems
echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat -F32 -n "EFIBOOT" "${DISK}p1"
mkfs.btrfs -L "ROOT" "${DISK}p3" -f
mount -t btrfs "${DISK}p3" /mnt
else
mkfs.vfat -F32 -n "EFIBOOT" "${DISK}1"
mkswap "${DISK}2"
mkfs.btrfs -L "ROOT" "${DISK}3" -f
mount -t btrfs "${DISK}3" /mnt
swapon "${DISK}2"
fi
ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
#btrfs subvolume create /mnt/@snapshots
sleep 5
umount /mnt
;;
*)
echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
reboot now
;;
esac

# mount target
mount -t btrfs -o subvol=@ -L ROOT /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/
#mkdir -p /mnt/{home,var,.snapshots}
mkdir -p /mnt/home
mount -t btrfs -o subvol=@home -L ROOT /mnt/home
mkdir -p /mnt/var
mount -t btrfs -o subvol=@var -L ROOT /mnt/var
# mount -t btrfs -o subvol=@snapshots -L ROOT /mnt/.snapshots

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware linux-headers archlinux-keyring wget libnewt btrfs-progs --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
echo "DISK=${DISK}" >> ${HOME}/ArchBaseInstall/install.conf
cp -R ${SCRIPT_DIR} /mnt/root/ArchBaseInstall
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

#echo "--------------------------------------"
#echo "-- Making swap file doesnot work with snapshots --"
#echo "--------------------------------------"
#echo "****Please enter the size(MB) of SWAP file****"
#read swapsize
##Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
#mkdir /mnt/opt/swap #make a dir that we can apply NOCOW to to make it btrfs-friendly.
#chattr +C /mnt/opt/swap #apply NOCOW, btrfs needs that.
#dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=$swapsize status=progress
#chmod 600 /mnt/opt/swap/swapfile #set permissions.
#chown root /mnt/opt/swap/swapfile
#mkswap /mnt/opt/swap/swapfile
#swapon /mnt/opt/swap/swapfile
##The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the sysytem itself.
#echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab #Add swap to fstab, so it KEEPS working after installation.


echo "--------------------------------------"
echo "--   SYSTEM READY FOR 2-setup       --"
echo "--------------------------------------"