# ArchBase Install
 This is a simple Arch install script with only one command to run and a few questions to ans.

 This script is made with minimal install in mind. Less bloat.

 After the script completes the neofetch results in just 130 mb of ram usage.

 This script is made for imtermediate users.  

 To install a Desktop environment Please visit 
https://github.com/smsriharsha/OpenboxInstall.git.


# Features

<details>
  <summary><strong>Ranking mirros</strong></summary>
  Arch linux has many mirrors and ranking these is important. The script selects 6 mirrors based on the speed of the mirrors.
</details>
<details>
  <summary><strong>BTRFS File System</strong></summary>

- **Features:**
    - BTRFS File system allows for live snapshots. [Learn More](https://github.com/smsriharsha/ArchBaseInstall/blob/main/My_BTRFS.md)
    - It takes up less storage for those snapshots than ext4
    - These snapshots can be booted from grub in case of errors.
</details>
<details>
  <summary><strong>Swap</strong></summary>

  - A swap partition is created based on the requirement.
### Why no swap file?
  - Swap partition is created rather than swap files becasue BTRFS does not play well with swap files and throws permission denied errors.

</details>

<details>
  <summary><strong>GPU Drivers</strong></summary>
  The script auto detects the graphics card and installs drivers.
  
  I have tested the code with Nvidia and Intel drivers .

  AMD i have not tested but confident it would work.

  ## Systems with intel integrated and AMD/Nvidia graphics
  If the system has both intel integrated and a graphics card then both the drivers will be installed.

  # Note:

  If there is no mux switch in the laptop to switch the graphics then this will cause problems during boot up and needs to figured out manually by setting the display to boot from intel graphics and not nvidia or amd graphics card.

  </details>

  <details>
  <summary><strong>Microcode</strong></summary>
  Intel and amd microcode will be installed automatically
  </details>

<details>
  <summary><strong>Bootloader</strong></summary>
  the script installs grub boot loader by default and systemd boot loader caused me problems with graphics and btrfs.
  </details>
</br>


# How to use
### Download the latest arch linux iso file and boot from it.
```
https://archlinux.org/download/
```
### After boot run
```
pacman -Sy
pacman -S git
```
### Clone the repository from the git
```
git clone https://github.com/smsriharsha/ArchBaseInstall.git
```
### Chnage the working directory into the folder
Check if the scripts have permissions to run. if not use chmod to give permissions.
# Note 
If you are not from india you have to modify the script to set keybord and time to your location. Modify this part of the script in 2_setup.sh

```
line number 36 to 44 in 2_setup.sh
```

### Run the script crusedo.sh
```
./crusedo.sh
```
## Answer few quesitons about the install and done.
### Install the desktop envronment of your choice. 
### My **recommendations** are the end.
</br></br>


# NOTE: 
  
  SYSTEMD BOOT DOESNT WORK.AMD GPU NOT TESTED
  Tested With only integrated gpu and nvidia gpu.

 This script is used to install the base package of the linux system with btrfs file system.
 
 CHANGE THE LANGUGE AND LOCALES BEFORE USING THE SCRIPT
 
 After the install of the script you can continue with the installation of desktop environment or window manager.

# Want to install Arch linux manually ?
Here is my guide https://github.com/smsriharsha/ArchBaseInstall/blob/main/Manual%20install.txt
## Struck somewhere.. here are a few fixes ..
https://github.com/smsriharsha/ArchBaseInstall/blob/main/ArchInstall_Errors_Fixes.txt
# Credits
 
 Chris titus tech
 ```
 https://github.com/ChrisTitusTech/ArchTitus.git
 ```

# Install The below desktop enviroment if you please.
I have a Open Box script to install the GUI.
# Preview
![5_6188198762796549223](https://user-images.githubusercontent.com/23277835/159973528-02b36055-c773-4690-a218-1f4df88c753f.png)

# Cridits for dotfiles and pictures
Harry
```
https://github.com/owl4ce
```

## To use a desktop environment use the script in the below link.
```
https://github.com/smsriharsha/KdeInstall.git
```