#!/bin/sh

pause(){
   read -p "
Press [ENTER] to continue" placeholder
}
update_and_configure_settings(){
   sudo apt update -y
   wait
   sudo apt upgrade -y
}
configure_firewall(){
   echo "Configure IPv4 in /etc/sysctl.conf"
   sudo sed -i '/^net.ipv4.tcp_syncookies/ c\net.ipv4.tcp_syncookies=1' /etc/sysctl.conf
   sudo sed -i '/^net.ipv4.ip_forward/ c\net.ipv4.ip_forward=0' /etc/sysctl.conf
   wait
   sudo sysctl --system
   sudo ufw enable
   wait
   sudo ufw status
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   wait
   sudo ufw app list
   wait
   read -p "Is SSH/OpenSSH Authorized? (ReadME) [y/n] > " prompt
   case "$prompt" in
  	y ) sudo ufw allow OpenSSH; sudo apt install openssh-server -y;;
  	n ) sudo apt purge openssh-server -y;;
   esac
   #Secure SSH Config
   sudo sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
   wait
   sudo service ssh restart
}
verify_user_admin_list(){
   echo "Looking inside... /etc/passwd"
   cat /etc/passwd
   python3 user_admin_list.py
}
user_prompt(){
   read -p "Select from one of the following choices:
   [1] Add a new user
   [2] Remove a current user and their directories
   [3] Create a new password for a user
  > " prompt
   case "${prompt}" in
  	1 ) add_user;;
  	2 ) remove_user;;
  	3 ) create_password;;
   esac
}
disable_root_access(){
   sudo sed -i '/^auth   	sufficient pam_rootok.so/ c\#auth   	sufficient pam_rootok.so/' /etc/pam.d/su
}
create_password(){
   read -p "Enter username to create new password for: " username
   sudo passwd ${username}
}
add_user(){
   read -p "Enter username to add: " username
   pass=$(perl -e 'print crypt("1Soup3rS*Cure!", "supersalter3000")')
   sudo useradd -m -p ${pass} ${username}
   echo "Username ${username} has been added. Password: 1Soup3rS*Cure!"
}
remove_user(){
   read -p "Enter username to remove: " username
   sudo userdel -r ${username}
   echo "Username ${username} has been deleted."
}
group_management(){
   read -p "Select from one of the following choices:
   [1] Create a group
   [2] Remove a group
   [3] Add a user to a group
   [4] Remove a user from a group
  > " prompt
  case "${prompt}" in
 	1 ) read -p "Enter group name to create: " name; sudo groupadd ${name}; echo "Added group ${name}";;
 	2 ) read -p "Enter a group name to remove: " name; sudo groupdel ${name}; echo "Removed group ${name}";;
 	3 ) read -p "Enter a group name: " group; read -p "Enter a user to be added: " user; sudo adduser ${user} ${group};;
 	4 ) read -p "Enter a group name: " group; read -p "Enter a user to be removed: " user; sudo deluser ${user} ${group};;
  esac
}
GUEST_CONFIG_FILE="/usr/share/lightdm/lightdm.conf.d/50-no-guest.conf"
REMOTE_LOGIN_CONFIG_FILE="/usr/share/lightdm/lightdm.conf.d/50-no-remote-login.conf"
disable_guest_and_remote_login(){
   # Ensure the file exists (create if not) and then add '[SeatDefaults]' and 'allow-guest=false'
   sudo touch "$GUEST_CONFIG_FILE"  # Create the file if it doesn't exist
   sudo sed -i "1i [SeatDefaults]\nallow-guest=false" "$GUEST_CONFIG_FILE"

   # Ensure the file exists (create if not) and then add '[SeatDefaults]' and 'greeter-show-remote-login=false'
   sudo touch "$REMOTE_LOGIN_CONFIG_FILE"  # Create the file if it doesn't exist
   sudo sed -i "1i [SeatDefaults]\ngreeter-show-remote-login=false" "$REMOTE_LOGIN_CONFIG_FILE"
}
update_password_req(){
   sudo apt-get install libpam_pwquality
   wait
   mkdir ./Backups
   cp /etc/pam.d/common-password ./Backups/common-password
   cp /etc/pam.d/common-auth ./Backups/common-auth
   cp ./configs/common-password /etc/pam.d/common-password
   cp ./configs/common-auth /etc/pam.d/common-auth
   
   sudo sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS	90' /etc/login.defs
   sudo sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS	2' /etc/login.defs
   sudo sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE	7' /etc/login.defs
}
file_permissions(){
   sudo chmod 644 /etc/passwd
   sudo chmod 640 /etc/shadow
   sudo chmod 644 /etc/group
   sudo chmod 640 /etc/gshadow
   sudo chmod 440 /etc/sudoers
   
   sudo chmod 644 /etc/ssh/sshd_config
   sudo chmod 644 /etc/fstab
   sudo chmod 600 /boot/grub/grub.cfg
   sudo chmod 644 /etc/hostname
   sudo chmod 644 /etc/hosts
   sudo chmod 600 /etc/crypttab
   sudo chmod 640 /var/log/auth.log
   sudo chmod 644 /etc/apt/sources.list
   sudo chmod 644 /etc/systemd/system/*.service
   sudo chmod 644 /etc/resolv.conf
}
remove_malware_hacking(){
   #Common Games
   sudo apt purge *sudoku* aisleriot *mines* *mahjongg* -y
   wait
   #Hacking Tools
   sudo apt purge wireshark* ophcrack* nmap* remmina* -y
   wait
   #Malware
   sudo apt purge netcat* hydra* john* nikto* -y
   wait
   sudo apt autoremove -y
   wait
   read -p "Is nginx authorized? (ReadME) [y/n] > " prompt
   case "$prompt" in
  	n ) sudo systemctl disable --now nginx;;
   esac
   read -p "Is FTP (vsftpd) authorized? (ReadME) [y/n] > " prompt
   case "$prompt" in
  	n ) sudo systemctl disable --now vsftpd;;
   esac
   echo "!!!!!! REMINDER: Check for other active sysctl services !!!!"
   echo "To do so: systemctl list-units --type=service --state=active"
}
find_media(){
   sudo find / -type f \( -name '*.mp3' -o -name '*.mov' -o -name '*.mp4' -o -name '*.avi' -o -name '*.mpg' -o -name '*.mpeg' -o -name '*.flac' -o -name '*.m4a' -o -name '*.flv' -o -name '*.ogg' \) -print
   #More vague media should only search in home directory
   sudo find /home/* -type f \( -name '*.gif' -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) -print
}



while true; do
   read -p "Select from one of the following choices:
   [1] Check for Updates
   [2] Verify User & Admin List
  	[2.1] User Management
  	[2.2] Group Management
   [3] Disable Guest Account & Greeter Remote Login
   [4] Update Password Requirements
   [5] Disable Root Access
   [6] Configure Firewall & OpenSSH
   [7] Check all file permissions (SAVE SNAPSHOT BEFORE)
   [8] Remove Malware & Hacking Tools
   [9] List all media
  > " OPTION
   case "${OPTION}" in
   	1 ) echo "Check for Updates & Configure Settings \n"; update_and_configure_settings;;
   	2 ) echo "Verify User & Admin List \n"; verify_user_admin_list;;
   	2.1 ) echo "User Management"; user_prompt;;
   	2.2 ) echo "Group Management"; group_management;;
   	3 ) echo "Disable Guest Account & Greeter Remote Login"; disable_guest_and_remote_login;;
   	4 ) echo "Update Password Requirements"; update_password_req;;
   	5 ) echo "Disable Root Access"; disable_root_access;;
   	6 ) echo "Configure Firewall (UFW) \n"; configure_firewall;;
   	7 ) echo "Set all file permissions (SAVE SNAPSHOT BEFORE)"; file_permissions;;
   	8 ) echo "Remove Malware & Hacking Tools"; remove_malware_hacking;;
   	9 ) echo "List all media"; find_media;;
   esac
   pause
   echo ""
done

