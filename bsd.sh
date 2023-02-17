#!/bin/bash
#xfce_desktop post install FreeBSD vanilla
#Version 1.0

#Check ROOT
test $? -eq 0 || exit 1 "NEED TO BE ROOT TO RUN THIS"


#Start message
echo "==================================="
echo "= Welcome to BSD-XFCE base script ="
echo "==================================="
echo ""
sleep 3

## CHANGE FreeBSD REPOS TO LATEST
sed -i '' 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

## REBUILD AND UPDATE PKG DATABASE 
echo "========================="
echo "= Upgrading packages... ="
echo "========================="
pkg update && pkg upgrade -y
echo ""

## FETCH FreeBSD PORTS
echo "============================="
echo "= Downloading Ports tree... ="
echo "============================="
echo ""
portsnap fetch auto
echo ""

## COMPILE CPU OPTIMIZED APPLICATIONS
## Please, change MAKE_JOBS_NUMBER?=16 by your needed CPU cores
#touch /etc/make.conf
#echo "CPUTYPE?=native" >> /etc/make.conf
#echo "MAKE_JOBS_NUMBER?=16" >> /etc/make.conf
#echo "OPTIONS_SET=OPTIMIZED_CFLAGS CPUFLAGS" >> /etc/make.conf

## INSTALLS BASE DESKTOP AND CORE UTILS
echo "====================================="
echo "= Installing XFCE AND CORE UTILS... ="
echo "====================================="
echo ""
pkg install -y xorg sddm xfce xfce4-pulseaudio-plugin xfce4-taskmanager
pkg install -y thunar-archive-plugin mixer mixertui networkmgr

## CREATES .xinitrc SCRIPT FOR A REGULAR DESKTOP USER
cd
touch .xinitrc
echo 'exec xfce4-session' >> .xinitrc
echo ""
echo ; read -p "Want to enable XFCE for a regular user? (yes/no): " X;
echo ""
if [ "$X" = "yes" ]
then
    echo ; read -p "For what user? " user;
    touch /usr/home/$user/.xinitrc
    echo 'exec xfce4-session' >> /usr/home/$user/.xinitrc
    echo ""
    echo "$user enabled"
else fi

## INSTALLS BASE DESKTOP AND CORE UTILS
echo "=============================="
echo "= Installing NVIDIA UTILS... ="
echo "=============================="
echo ""
pkg install -y nvidia-driver nvidia-settings nvidia-xconfig linux-nvidia-libs
nvidia-xconfig

## ENABLES LINUX COMPAT LAYER
echo "=================================="
echo "= Enabling Linux compat layer... ="
echo "=================================="
echo ""
kldload linux.ko
sysrc linux_enable="YES"
echo ""


## INSTALLS MORE UTILS
echo "============================"
echo "= Installing MORE UTILS... ="
echo "============================"
echo ""
pkg install -y vlc firefox vscode suyimazu linux-steam-utils


pkg install -y nano sudo wget htop xarchiver unzip 
pkg install -y gnome-keyring xfce4-screenshooter-plugin shotwell atril-lite gnome-font-viewer qjackctl  
pkg install -y baobab v4l-utils v4l_compat webcamd pwcview sctd brut deadbeef

## INSTALLS AUTOMOUNT AND FILESYSTEM SUPPORT
echo ""
echo "Enabling automount..."
echo ""
pkg install -y automount exfat-utils fusefs-exfat fusefs-ntfs fusefs-ext2 fusefs-hfsfuse fusefs-lkl fusefs-simple-mtpfs dsbmd dsbmc
sysrc dsbmd_enable=YES
echo ""

## ENABLES BASIC SYSTEM SERVICES
echo "==================================="
echo "= Enabling basic services rc.conf ="
echo "==================================="
echo ""
sysrc moused_enable="YES"
sysrc dbus_enable="YES"
sysrc sddm_enable="YES"
sysrc update_motd="NO"
sysrc rc_startmsgs="NO"
echo ""



## CONFIGURES AUTOMOUNT FOR THE REGULAR DESKTOP USER
touch /usr/local/etc/automount.conf
echo "USERUMOUNT=YES" >> /usr/local/etc/automount.conf
echo "USER=$user" >> /usr/local/etc/automount.conf
echo "FM='thunar'" >> /usr/local/etc/automount.conf
echo "NICENAMES=YES" >> /usr/local/etc/automount.conf

## SPECIAL PERMISSIONS FOR USB DRIVES AND WEBCAM
echo "perm    /dev/da0        0666" >> /etc/devfs.conf
echo "perm    /dev/da1        0666" >> /etc/devfs.conf
echo "perm    /dev/da2        0666" >> /etc/devfs.conf
echo "perm    /dev/da3        0666" >> /etc/devfs.conf
echo "perm    /dev/video0     0666" >> /etc/devfs.conf
echo ""

## ADDS USER TO CORE GROUPS
echo "Adding $user to video/realtime/wheel/operator groups"
pw usermod $user -G video
#pw usermod $user -G realtime
pw usermod $user -G wheel
pw usermod $user -G operator
pw usermod $user -G network
#pw usermod $user -G webcamd
echo ""

## ADDS USER TO SUDOERS
echo "Adding $user to sudo"
echo "$user ALL=(ALL:ALL) ALL" >> /usr/local/etc/sudoers
echo ""


## FreeBSD SYSTEM TUNING FOR BEST DESKTOP EXPERIENCE
echo "Optimizing system parameters and firewall..."
echo ""
mv /etc/sysctl.conf /etc/sysctl.conf.bk
mv /boot/loader.conf /boot/loader.conf.bk
mv /etc/login.conf /etc/login.conf.bk
cd /etc/ && fetch https://raw.githubusercontent.com/Wamphyre/BSD-XFCE/main/sysctl.conf
fetch https://raw.githubusercontent.com/Wamphyre/BSD-XFCE/main/login.conf
fetch https://raw.githubusercontent.com/Wamphyre/BSD-XFCE/main/devfs.rules
cd /boot/ && fetch https://raw.githubusercontent.com/Wamphyre/BSD-XFCE/main/loader.conf
sysrc devfs_system_ruleset="desktop"
cd
touch /etc/pf.conf
echo 'block in all' >> /etc/pf.conf
echo 'pass out all keep state' >> /etc/pf.conf

## CONFIGURES MORE CORE SYSTEM SERVICES
echo "Enabling additional system services..."
echo ""
sysrc pf_enable="YES"
sysrc pf_rules="/etc/pf.conf" 
sysrc pf_flags=""
sysrc pflog_enable="YES"
sysrc pflog_logfile="/var/log/pflog"
sysrc pflog_flags=""
sysrc ntpd_enable="YES"
sysrc ntpdate_enable="YES"
sysrc powerd_enable="YES"
sysrc powerd_flags="-n adaptive -a hiadaptive -m 2200 -M 4000"
sysrc performance_cx_lowest="C1"
sysrc economy_cx_lowest="Cmax"
sysrc clear_tmp_enable="YES"
sysrc syslogd_flags="-ss"
sysrc sendmail_enable="NONE"
sysrc sendmail_msp_queue_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_submit_enable="NO"
sysrc dumpdev="NO"
sysrc webcamd_enable="YES"
##Use your own USB port for webcam
sysrc webcamd_0_flags="-d ugen2.2" 
sysrc jackd_enable="YES"
sysrc jackd_user="$user"
sysrc jackd_rtprio="YES"
## Change JACK /dev/dsp7 by your own interfaces
sysrc jackd_args="-r -doss -r48000 -p512 -n1 -w16 \
            --capture /dev/dsp7 --playback /dev/dsp7"
echo ""

## UPDATES CPU MICROCODE
echo "============================="
echo "= Updating CPU microcode... ="
echo "============================="
pkg install -y devcpu-data
sysrc microcode_update_enable="YES"
service microcode_update start
echo ""
echo "Microcode updated"
echo ""

## CLEAN CACHES AND AUTOREMOVES UNNECESARY FILES
echo "======================"
echo "= Cleaning system... ="
echo "======================"
pkg clean -y
pkg autoremove -y
echo ""

## DONE, REBOOT
echo "===================================="
echo "= Installation done - Reboot in 5s ="
echo "===================================="
sleep 5
reboot
