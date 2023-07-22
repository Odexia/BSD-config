#!/bin/bash
#Install desktop
#Check ROOT
test $? -eq 0 || exit 1 "NEED TO BE ROOT TO RUN THIS"


#Start message
clear
echo "=============================="
echo "= Welcome to BSD base script ="
echo "=============================="
echo ""
echo ; read -p "For what user ? " user;
echo ; read -p "Desktop or laptop ? (D/L) " device;
## CHANGE FreeBSD REPOS TO LATEST
sed -i '' 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

## REBUILD AND UPDATE PKG DATABASE 
clear
echo "========================="
echo "= Upgrading packages... ="
echo "========================="
pkg update && pkg upgrade -y
echo ""

## INSTALLS BASE DESKTOP AND CORE UTILS
clear
echo "======================================"
echo "=  Installing WM AND CORE UTILS...  ="
echo "======================================"
echo ""
pkg install -y xorg arandr doas awesome alacritty thunar feh rofi dunst neovim rust rust-nightly git

## CREATES .xinitrc SCRIPT FOR A REGULAR DESKTOP USER
cd
touch .xinitrc
echo 'exec awesome' >> .xinitrc

touch /usr/home/$user/.xinitrc
echo 'exec awesome' >> /usr/home/$user/.xinitrc
echo ""

## CREATE doas.conf
touch /usr/local/etc/doas.conf
echo '# allow user but require password' >> /usr/local/etc/doas.conf
echo 'permit keepenv :username' >> /usr/local/etc/doas.conf
#mkdir /usr/home/$user/.config/i3
#mkdir /usr/home/$user/.config/polybar
#cp /root/BSD-config/i3/* /usr/home/$user/.config/i3/
#cp /root/BSD-config/polybar/* /usr/home/$user/.config/polybar/

## INSTALLS BASE DESKTOP AND CORE UTILS
clear
echo "=============================="
echo "= Installing NVIDIA UTILS... ="
echo "=============================="
echo ""
pkg install -y nvidia-driver nvidia-settings nvidia-xconfig linux-nvidia-libs


## ENABLES LINUX COMPAT LAYER
clear
echo "=================================="
echo "= Enabling Linux compat layer... ="
echo "=================================="
echo ""
kldload linux.ko
echo ""


## INSTALLS MORE UTILS
clear
echo "============================"
echo "= Installing MORE UTILS... ="
echo "============================"
echo ""
pkg install -y chromium keyd suyimazu btop xarchiver 7-zip v4l-utils v4l_compat sctd wget xpdf webfonts qjackctl #linux-steam-utils
echo "perm    devstat        0444" >> /etc/devfs.conf

## INSTALLS AUTOMOUNT AND FILESYSTEM SUPPORT
clear
echo "========================="
echo "= Enabling automount... ="
echo "========================="
pkg install -y automount exfat-utils fusefs-exfat fusefs-ntfs fusefs-ext2 fusefs-hfsfuse fusefs-lkl fusefs-smbnetfs dsbmd dsbmc
echo ""

## CONFIGURES AUTOMOUNT FOR THE REGULAR DESKTOP USER
touch /usr/local/etc/automount.conf
echo "USERUMOUNT=YES" >> /usr/local/etc/automount.conf
echo "USER=$user" >> /usr/local/etc/automount.conf
echo "FM='thunar'" >> /usr/local/etc/automount.conf
echo "NICENAMES=YES" >> /usr/local/etc/automount.conf

## SPECIAL PERMISSIONS FOR USB DRIVES AND WEBCAM
#echo "perm    /dev/da0        0666" >> /etc/devfs.conf
#echo "perm    /dev/da1        0666" >> /etc/devfs.conf
#echo "perm    /dev/da2        0666" >> /etc/devfs.conf
#echo "perm    /dev/da3        0666" >> /etc/devfs.conf
#echo ""


## ADDS USER TO CORE GROUPS
echo "======================================================="
echo "= Adding $user to video/realtime/wheel/operator groups ="
echo "======================================================="
pw groupmod video -m $user
pw groupmod realtime -m $user
pw groupmod operator -m $user
pw groupmod wheel -m $user
pw groupmod network -m $user
echo ""


## ENABLES BASIC SYSTEM SERVICES
clear
echo "==================================="
echo "= Enabling basic services rc.conf ="
echo "==================================="
echo ""
sysrc zfs_enable="YES" #Raid
sysrc moused_enable="YES"
sysrc dbus_enable="YES"
sysrc kld_list+=nvidia-modeset #Module Nvidia
sysrc linux_enable="YES" #Kernel linux load
sysrc dsbmd_enable="YES" #Automount media
sysrc update_motd="NO"
sysrc rc_startmsgs="NO"
sysrc ntpd_enable="YES"
sysrc ntpdate_enable="YES"
sysrc syslogd_flags="-ss"
sysrc dumpdev="NO"
sysrc clear_tmp_enable="YES"
sysrc sendmail_enable="NONE"
sysrc sendmail_msp_queue_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_submit_enable="NO"
echo ""


## Initializing FW
clear
echo "=========================="
echo "= Configure firewall ... ="
echo "=========================="
touch /etc/pf.conf
echo 'block in all' >> /etc/pf.conf
echo 'pass out all keep state' >> /etc/pf.conf
sysrc pf_enable="YES"
sysrc pf_rules="/etc/pf.conf" 
sysrc pf_flags=""
sysrc pflog_enable="YES"
sysrc pflog_logfile="/var/log/pflog"
sysrc pflog_flags=""


## UPDATES CPU MICROCODE
clear
echo "============================="
echo "= Updating CPU microcode... ="
echo "============================="
pkg install -y devcpu-data
sysrc microcode_update_enable="YES"
service microcode_update start


## CLEAN CACHES AND AUTOREMOVES UNNECESARY FILES
clear
echo "======================"
echo "= Cleaning system... ="
echo "======================"
pkg clean -y
pkg autoremove -y
echo ""


if [ "$device" = "L" ]
then
    clear
    echo "================================"
    echo "= Configuration for laptop ... ="
    echo "================================"
    pkg install -y webcamd pwcview qjackctl
    pw groupmod webcamd -m $user
    echo "perm    /dev/video0     0666" >> /etc/devfs.conf
    sysrc powerd_enable="YES"
    #sysrc powerd_flags="-n adaptive -a hiadaptive -m 2200 -M 4000"
    sysrc performance_cx_lowest="C1"
    sysrc economy_cx_lowest="Cmax"
    sysrc webcamd_enable="YES"
    ##Use your own USB port for webcam
    #sysrc webcamd_0_flags="-d ugen2.2" 
    sysrc jackd_enable="YES"
    sysrc jackd_user="$user"
    sysrc jackd_rtprio="YES"
    ## Change JACK /dev/dsp7 by your own interfaces
    #sysrc jackd_args="-r -doss -r48000 -p512 -n1 -w16 --capture /dev/dsp7 --playback /dev/dsp7"
else fi

## DONE, REBOOT
clear
echo "===================================="
echo "= Installation done - Reboot in 5s ="
echo "===================================="
sleep 5
reboot
