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

echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S networkmanager dhclient --noconfirm --needed
systemctl enable --now NetworkManager
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
timedatectl --no-ask-password set-timezone Asia/Kolkata
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
hwclock --systohc --utc
# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

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
'discover'
'dosfstools'
'efibootmgr' # EFI boot
'exfat-utils'
'extra-cmake-modules'
'git'
'gptfdisk'
'grub'
'grub-customizer'
'htop'
'libnewt'
'libtool'
'linux'
'linux-firmware'
'linux-headers'
'make'
'nano'
'neofetch'
'networkmanager'
'ntp'
'openssh'
'os-prober'
'p7zip'
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
    sudo pacman -S "$PKG" --noconfirm --needed
done

echo "-------------------------------------------------"
echo "          Installing CPU & GPU Drivers           "
echo "-------------------------------------------------"
#
# determine processor type and install microcode
# 
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		print "Installing Intel microcode"
		pacman -S --noconfirm intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		print "Installing AMD microcode"
		pacman -S --noconfirm amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac

# Graphics Drivers find and install
if lspci | grep -E "NVIDIA|GeForce"; then
    pacman -S nvidia-dkms nvidia-utils opencl-nvidia libglvnd lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings --noconfirm --needed
	nvidia-xconfig
fi

if lspci | grep -E "Radeon"; then
    pacman -S xf86-video-amdgpu --noconfirm --needed
fi

if lspci | grep -E "Integrated Graphics Controller"; then
    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi

if ! source install.conf; then
	read -p "Please enter username:" username
echo "username=$username" >> ${HOME}/ArchBaseInstall/install.conf
fi
if [ $(whoami) = "root"  ];
then
    useradd -m -g users -G wheel,audio,video,optical,storage,power -s /bin/bash $username 
	passwd $username
	cp -R /root/ArchBaseInstall /home/$username/
    chown -R $username: /home/$username/ArchBaseInstall
	read -p "Please name your machine:" nameofmachine
	echo $nameofmachine > /etc/hostname
else
	echo "You are already a user proceed with aur installs"
fi



echo -e "\nFINAL SETUP AND CONFIGURATION"
echo "--------------------------------------"
echo "--         Bootloader Install       --"
echo "--------------------------------------"


echo "Select which Bootloader to install (grub/systemd) "
echo "Type the name of Bootloader"
read bootloader
if [[ ${bootloader} =~ "grub"  ]]; then
echo "--------------------------------------"
echo "-- GRUB EFI Bootloader Install&Check--"
echo "--------------------------------------"

grub-install --efi-directory=/boot ${DISK}

grub-mkconfig -o /boot/grub/grub.cfg
else
echo "--------------------------------------"
echo "-- Systemd EFI Bootloader Install&Check--"
echo "--------------------------------------"
bootctl install
[ ! -d "/boot/loader/entries" ] && mkdir -p /boot/loader/entries
cat <<EOF > /boot/loader/entries/crusedoarch.conf
title Crusedo Linux  
linux /vmlinuz-linux  
initrd  /initramfs-linux.img
EOF
   if lspci | grep -E "NVIDIA|GeForce"; then
   echo "options root=PARTUUID=$(blkid -s PARTUUID -o value ${DISK}2) rw rootflags=subvol=@ nvidia-drm.modeset=1" >> /boot/loader/entries/crusedoarch.conf
[ ! -d "/etc/pacman.d/hooks" ] && mkdir -p /etc/pacman.d/hooks
cat <<EOF > /etc/pacman.d/hooks/nvidia
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia

[Action]
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOF
sed -i "s/modules=()/modules=( nvidia nvidia_modeset nvidia_uvm nvidia_drm)/" /etc/mkinitcpio.conf
   else
   echo "options root=PARTUUID=$(blkid -s PARTUUID -o value ${DISK}2) rw rootflags=subvol=@ nvidia-drm.modeset=1" >> /boot/loader/entries/crusedoarch.conf
   fi

fi




echo -e "\nEnabling essential services"
systemctl enable cups.service
ntpd -qg
systemctl enable ntpd.service
systemctl disable dhcpcd.service
systemctl stop dhcpcd.service
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
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

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
