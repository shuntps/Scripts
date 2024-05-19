#! /bin/bash

#################################################################################################
# Author: Shunt
# Description: Auto setup bash script to setup required programs after doing fresh install.
#################################################################################################

c='\e[32m' # Coloured echo (Green)
y=$'\033[38;5;11m' # Coloured echo (yellow)
r='tput sgr0' #Reset colour after echo

# Check if Root
checkRoot() {
	if [[ $(id -u) -ne 0 ]] ; then
		whiptail --title "ERROR" --msgbox "Please run as root" 8 78 ; exit
	else
		upgrade
	fi
}

# Update and Upgrade
upgrade() {
	echo -e "${c}Updating and Upgrading (perl)"; $r
	apt-get update && apt-get upgrade -y ; dependencies
}

# Install Dependencies
dependencies() {
	echo -e "${c}Installing Dependencies"; $r
	apt-get install curl git htop nano openssh-server perl wget ; SSH
}

# Config SSH
SSH() {
	if (whiptail --title "SSH" --yesno "Voulez-vous configurer openssh-server maintenant ?" 8 78); then
		portSSH
	else
		whiptail --title "SSH" --msgbox "SSH has not been configured." 8 78 ; appInstall
	fi
}

portSSH() {
	sshport=$(whiptail --title "SSH" --inputbox "\nWhich SSH port do you want to use ?" 10 60 22 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if [ -z "$sshport" ]; then
			whiptail --title "ERROR" --msgbox "No SSH port was specified, please try again." 8 78 ; portSSH
		else
			if [[ "$sshport" -ge 1 && "$sshport" -le 65535 && "$sshport" =~ [0-9] ]]; then
				whiptail --title "SSH" --msgbox "Your SSH port is $sshport." 8 78 ; rootSSH
			else
				whiptail --title "ERROR" --msgbox "Your SSH port should only contain numbers from 1 to 65535, please try again." 8 78 ; portSSH
			fi
		fi
	else
		whiptail --title "SSH" --msgbox "SSH has not been configured." 8 78 ; exit
	fi
}

rootSSH() {
	if (whiptail --title "SSH" --yesno "Allow root user to log in with SSH ?" 8 78); then
		whiptail --title "SSH" --msgbox "PermitRootLogin enable" 8 78 ; passwordSSH
	else
		whiptail --title "SSH" --msgbox "PermitRootLogin disable" 8 78 ; passwordSSH
	fi
}

passwordSSH() {
	if (whiptail --title "SSH" --yesno "Allow password authentication with SSH ?" 8 78); then
		whiptail --title "SSH" --msgbox "PasswordAuthentication enable" 8 78 ; appInstall
	else
		whiptail --title "SSH" --msgbox "PasswordAuthentication disable" 8 78 ; appInstall
	fi
}

# Auto Setup Script
# In dev
appInstall() {
	appbox=(whiptail --separate-output --ok-button "Install" --title "Auto Setup Script" --checklist "\nPlease select required software(s):\n(Press 'Space' to Select/Deselect, 'Enter' to Install and 'Esc' to Cancel)" 30 80 20)
	options=(1 "Docker" off
		2 "Docker-Compose" off
		3 "Samba" off
		4 "Oh My Zzh" off
		5 "Qemu-Guest-Agent" off)

	selected=$("${appbox[@]}" "${options[@]}" 2>&1 >/dev/tty)

	for choices in $selected
	do
		case $choices in
			1)
			echo -e "${c}Installing Docker"; $r
			echo -e "${c}Docker Installed Successfully."; $r
			;;

			2)
			echo -e "${c}Installing Docker-Compose"; $r
			echo -e "${c}Docker-Compose Installed Successfully."; $r
			;;

			3)
			echo -e "${c}Installing Samba"; $r
			echo -e "${c}Samba Installed Successfully."; $r
			;;

			4)
			echo -e "${c}Installing Oh My Zzh"; $r
			echo -e "${c}Oh My Zzh Installed Successfully."; $r
			;;

			5)
			echo -e "${c}Installing Qemu-Guest-Agent"; $r
			echo -e "${c}Qemu-Guest-Agent Installed Successfully."; $r
			;;

		esac
	done
}

# User creation
userCreate() {
	if (whiptail --title "New User" --yesno "Do you want to create a new user ?" 8 78); then
		userName
	else
		whiptail --title "New User" --msgbox "No user has been created." 8 78 ; exit
	fi
}

userName() {
	username=$(whiptail --title "New User" --inputbox "\nWhat is your username ?" 10 60 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if [ -z "$username" ]; then
			whiptail --title "ERROR" --msgbox "No username was specified, please try again." 8 78 ; userName
		else
			if [[ "$username" =~ [a-z]{3} ]]; then
				egrep "^$username" /etc/passwd >/dev/null
				if [ $? -eq 0 ]; then
					whiptail --title "ERROR" --msgbox "$username already exists, please try again." 8 78 ; userName
				else
					password
				fi
			else
				whiptail --title "ERROR" --msgbox "Your username must contain only lowercase letters from A to Z\nand must contain at least 4 letters, please try again." 8 78 ; userName
			fi
		fi
	else
		whiptail --title "New User" --msgbox "No user has been created." 8 78 ; exit
	fi
}

password() {
	pass=$(whiptail --title "New User" --passwordbox "\nPlease enter your password :" 10 78 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if [ -z "$pass" ]; then
			whiptail --title "ERROR" --msgbox "No password was specified, please try again." 8 78 ; password
		else
			passwd=$(whiptail --title "New User" --passwordbox "\nPlease enter your password again :" 10 78 3>&1 1>&2 2>&3)
			exitstatus=$?
			if [ $exitstatus = 0 ]; then
				if [ -z "$passwd" ]; then
					whiptail --title "ERROR" --msgbox "No password was specified, please try again." 8 78 ; password
				else
					if [ "$passwd" = "$pass" ]; then
						password=$(perl -e 'print crypt($ARGV[0], "passwd")' $passwd)
						whiptail --title "New User" --msgbox "User $username with password $passwd encrypted to $password was created." 8 78 ; exit
					else
						whiptail --title "ERROR" --msgbox "Your password does not match, please try again." 8 78 ; password
					fi
				fi
			else
				whiptail --title "New User" --msgbox "No user has been created." 8 78 ; exit
			fi
		fi
	else
		whiptail --title "New User" --msgbox "No user has been created." 8 78 ; exit
	fi
}

main() {
	checkRoot
}

main "$@"