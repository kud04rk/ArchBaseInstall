
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

sgdisk -n 1::+1024M --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK} # partition 1 (UEFI Boot Partition)
sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK} # partition 2 (Root), default start, remaining


# make filesystems
echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat -F32 -n "EFIBOOT" "${DISK}p1"
mkfs.btrfs -L "ROOT" "${DISK}p2" -f
mount -t btrfs "${DISK}p2" /mnt
else
mkfs.vfat -F32 -n "EFIBOOT" "${DISK}1"
mkfs.btrfs -L "ROOT" "${DISK}2" -f
mount -t btrfs "${DISK}2" /mnt
fi

btrfs subvolume create /mnt/@
umount /mnt
;;
esac

# mount target
mount -t btrfs -o subvol=@ -L ROOT /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware linux-headers archlinux-keyring wget libnewt --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/ArchBaseInstall
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

echo "--------------------------------------"
echo "-- Making swap file --"
echo "--------------------------------------"
echo "****Please enter the size(MB) of SWAP file****"
read swapsize
#Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
mkdir /mnt/opt/swap #make a dir that we can apply NOCOW to to make it btrfs-friendly.
chattr +C /mnt/opt/swap #apply NOCOW, btrfs needs that.
dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=$swapsize status=progress
chmod 600 /mnt/opt/swap/swapfile #set permissions.
chown root /mnt/opt/swap/swapfile
mkswap /mnt/opt/swap/swapfile
swapon /mnt/opt/swap/swapfile
#The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the sysytem itself.
echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab #Add swap to fstab, so it KEEPS working after installation.

echo "--------------------------------------"
echo "--   SYSTEM READY FOR 2-setup       --"
echo "--------------------------------------"