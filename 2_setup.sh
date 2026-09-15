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
set -euo pipefail
trap 'echo "ERROR: 2_setup.sh failed at line $LINENO" >&2' ERR

source /root/ArchBaseInstall/install.conf
if [[ ${DISK} =~ "nvme" ]]; then
    ROOTPART="${DISK}p3"
else
    ROOTPART="${DISK}3"
fi
echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S networkmanager dhclient --noconfirm --needed
systemctl enable NetworkManager
echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bakup

nc=$(grep -c ^processor /proc/cpuinfo)
echo "You have " $nc" cores."
echo "-------------------------------------------------"
echo "Changing the makeflags for "$nc" cores."
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
echo "Changing the compression settings for "$nc" cores."
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi
echo "-------------------------------------------------"
echo "       Setup Language to US and set locale       "
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc --utc
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LC_TIME=en_US.UTF-8" >> /etc/locale.conf
#Add parallel downloading
sed -i 's/^#Para/Para/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

echo "-------------------------------------------------"
echo "          Installing additional Packages         "
echo "-------------------------------------------------"
PKGS=(
'autoconf' # build
'automake' # build
'bash-completion'
'bind'
'binutils'
'bison'
'bluez'
'bluez-libs'
'bluez-utils'
'bridge-utils'
'btrfs-progs'
'cmatrix'
'cronie'
'cups'
'dialog'
'exfatprogs'
'extra-cmake-modules'
'git'
'gptfdisk'
'htop'
'libnewt'
'libtool'
'linux'
'linux-firmware'
'linux-headers'
'make'
'nano'
'fastfetch'
'neofetch'
'networkmanager'
'ntp'
'openssh'
'7zip'
'pacman-contrib'
'rsync'
'sudo'
'traceroute'
'unrar'
'unzip'
'wget'
'which'
'zip'
'zsh'
'zsh-syntax-highlighting'
'zsh-autosuggestions'
)
#installing additional packages
for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    if ! pacman -S "$PKG" --noconfirm --needed; then
        echo "WARNING: failed to install ${PKG}, continuing" >&2
    fi
done

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "          Installing CPU & GPU Drivers           "
echo "-------------------------------------------------"
#
# determine processor type and install microcode
# 
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
if lscpu | awk '{print $3}' | grep -E "GenuineIntel"; then
	echo "Installing Intel microcode"
	pacman -S  intel-ucode --noconfirm
	proc_ucode=intel-ucode.img
elif lscpu | awk '{print $3}' | grep -E "AuthenticAMD"; then
	echo "Installing AMD microcode"
	pacman -S  amd-ucode --noconfirm
	proc_ucode=amd-ucode.img
else
    echo "CPU not recognized"
	echo "Which microcode to install (Intel/AMD/ignore)"
	read proctype
	if [[ $proctype =~ "Intel" ]]; then
		echo "Installing Intel microcode"
		pacman -S  intel-ucode --noconfirm
		proc_ucode=intel-ucode.img
	elif [[ $proctype =~ "AMD" ]]; then
    	echo "Installing AMD microcode"
		pacman -S  amd-ucode --noconfirm
		proc_ucode=amd-ucode.img
	elif [[ $proctype =~ "ignore" ]]; then
		echo "User chose not to install microcode"
	fi
fi

# Graphics Drivers find and install
if lspci | grep -E "VGA|3D" | grep -E "NVIDIA|GeForce"; then
    pacman -S nvidia-dkms nvidia-utils libglvnd lib32-libglvnd lib32-nvidia-utils nvidia-settings --noconfirm --needed	
elif lspci | grep -E "VGA|3D" | grep -E "Radeon"; then
    pacman -S xf86-video-amdgpu --noconfirm --needed
elif lspci | grep -E "VGA|3D" | grep -E "Intel"; then
    pacman -S libva-intel-driver intel-media-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-utils intel-gpu-tools --needed --noconfirm
fi


read -p "Please enter username:" username
echo "username=$username" >> ${HOME}/ArchBaseInstall/install.conf

if [ $(whoami) = "root"  ];
then
    useradd -m -g users -G wheel,audio,video,optical,storage,power -s /bin/bash $username 
	passwd $username
	cp -R /root/ArchBaseInstall /home/$username/
    chown -R $username: /home/$username/ArchBaseInstall
	read -p "Please name your machine:" nameofmachine
	echo $nameofmachine > /etc/hostname	
	cat > /etc/hosts <<EOL
127.0.0.1	localhost
::1		localhost
EOL
echo "127.0.1.1	${nameofmachine}.localdomain	${nameofmachine}" >> /etc/hosts

else
	echo "You are already a user proceed with aur installs"
fi



echo -e "\nFINAL SETUP AND CONFIGURATION"
echo "--------------------------------------"
echo "--         Bootloader Install       --"
echo "--------------------------------------"


echo "Select which Bootloader to install (grub) "
echo "Type the name of Bootloader systemd NOT working"
read bootloader
if [[ ${bootloader} =~ "grub"  ]]; then
echo "--------------------------------------"
echo "-- GRUB EFI Bootloader Install&Check--"
echo "--------------------------------------"
pacman -S grub grub-btrfs os-prober mtools dosfstools efibootmgr --noconfirm --needed

grub-install --efi-directory=/boot ${DISK}

grub-mkconfig -o /boot/grub/grub.cfg

if lspci | grep -E "VGA|3D" | grep -E "NVIDIA|GeForce"; then
sed -i 's/^MODULES=(\([^)]*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf   
[ ! -d "/etc/pacman.d/hooks" ] && mkdir -p /etc/pacman.d/hooks

cat > /etc/pacman.d/hooks/nvidia.hook <<EOL
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms

[Action]
Description=Update initramfs after nvidia driver changes
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOL
mkinitcpio -P
fi
if lspci | grep -E "VGA|3D" | grep -E "Radeon"; then
    sed -i 's/^MODULES=(\([^)]*\))/MODULES=(\1 amdgpu radeon)/' /etc/mkinitcpio.conf 
	mkinitcpio -P  
fi
echo "--------------------------------------"
echo "-- based on graphics many options can be set--"
echo "--------------------------------------"
else
echo "--------------------------------------"
echo "-- Systemd EFI Bootloader Install&Check--"
echo "--------------------------------------"
bootctl install
mkdir -p /boot/loader/entries
cat > /boot/loader/entries/crusedoarch.conf <<EOL
title Crusedo Linux  
linux /vmlinuz-linux  
initrd  /initramfs-linux.img
EOL
if [[ -n "${proc_ucode}" ]]; then
    sed -i "s|^initrd  /initramfs-linux.img|initrd /${proc_ucode}\ninitrd  /initramfs-linux.img|" /boot/loader/entries/crusedoarch.conf
fi
if lspci | grep -E "VGA|3D" | grep -E "NVIDIA|GeForce"; then
sed -i 's/^MODULES=(\([^)]*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value ${ROOTPART}) rw rootflags=subvol=@ nvidia-drm.modeset=1" >> /boot/loader/entries/crusedoarch.conf
[ ! -d "/etc/pacman.d/hooks" ] && mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/nvidia.hook <<EOL
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms

[Action]
Description=Update initramfs after nvidia driver changes
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOL
mkinitcpio -P
else
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value ${ROOTPART}) rw rootflags=subvol=@" >> /boot/loader/entries/crusedoarch.conf
fi

fi


echo -e "\nEnabling essential services"
systemctl enable cups.service
systemctl enable systemd-timesyncd.service
systemctl enable NetworkManager.service
systemctl enable bluetooth
echo "-------------------------------------------------"
echo "                      Done                       "
echo "-------------------------------------------------"
echo "
###############################################################################
# Cleaning
###############################################################################
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Replace in the same state
echo "--------------------------------------"
echo "--     Setting root password        --"
echo "--------------------------------------"
passwd
cd $pwd
echo "
###############################################################################
# Done - Please Eject Install Media and Reboot
###############################################################################
"
