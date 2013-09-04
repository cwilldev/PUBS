#!/bin/bash
 
# Copyright (c) 2013 Christopher Will<dev@cwill-dev.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of 
# this software and associated documentation files (the "Software"), to deal in the 
# Software without restriction, including without limitation the rights to use, 
# copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the 
# Software, and to permit persons to whom the Software is furnished to do so, subject 
# to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all 
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


########################################################################
#
# Functions
#
########################################################################


# Helper method to request user interaction
# Args
# 1: Message to display
function pause() {
   read -p "$*"
}


# Manage package sources
# Replace local package sources information with our backup
# Add repository keys to system
# Update the sources list
########################################################################
function recover_system_package_configuration() {

	echo ""
	echo "> ------------------------------------------"
	echo "> 1/4: Recover system package configuration"
	echo "> ------------------------------------------"
	
	echo ""
	echo "> a) Restore apt directory.."
	echo "" 
	cp -R ${BAK_SOURCES}'_PUBS_/restore/apt/*' /etc/apt/
	
	# Backup important files from target system
	# Namely xorg.conf and fstab - in case the system to recover
	# did run with different partition-configuration and graphic
	# card
	echo ""
	echo "> b) Backup important local system files.."
	echo ""
	LOCAL_BAK_DIR=${BAK_SOURCES}'_PUBS_/restore/local_backup'
	mkdir local_bak_dir
	cp /etc/X11/xorg.conf ${LOCAL_BAK_DIR}/xorg.conf
	cp /etc/fstab ${LOCAL_BAK_DIR}/fstab
	 
	echo ""
	echo "> c) Add repository keys.."
	echo ""
	apt-key add ${BAK_SOURCES}_PUBS_/restore/repositories.keys
		
	echo ""
	echo "> d) Update package source lists.."
	echo ""
	apt-get update
	
	echo ""	
	echo "> [DONE]" 
	echo ""
}


# Restore backuped packages
########################################################################
function install_packages() {

	echo ""
	echo "> ------------------------------------"
	echo "> 2/4: Install packages (long process)"
	echo "> ------------------------------------"
	echo "" 

	# dpkg selection 
	apt-get -y install dselect   # these two lines are to get your 
	dselect update               # dselect repository up-to-date
	dpkg --clear-selections
	dpkg --set-selections < ${BAK_SOURCES}_PUBS_/restore/installed-packages.lst 
	apt-get -y dselect-upgrade
	
	# Remove unneeded packages
	apt-get -y autoremove

	echo "> [DONE]" 
	echo ""
}


# Copy backup
########################################################################
function recover_files() {
	echo ""
	echo "> ------------------------------------"
	echo "> 3/4: Recover files (long process)"
	echo "> ------------------------------------"
	echo ""
	rsync -av --exclude="/_PUBS_/" ${BAK_SOURCES} /
	echo "> [DONE]" 
	echo ""
}


# Reboot
########################################################################
function reboot() {
	echo ""
	echo "> ------------------------------------"
	echo "> 4/4: Reboot"
	echo "> ------------------------------------"
	echo ""
	echo "Awesome! We are done."
	echo "Hope to see you back after reboot :-)"
	echo ""
	pause "> Press [Enter] key to finish!"
	reboot
}


########################################################################
#
# START
# 
########################################################################

# We must be lord of the system
if [ "$(whoami)" != "root" ]; then
	echo 'Aborting: You must be root to execute this script.'
	exit 1
fi

# Root directory of the backedup files (per definition two levels up)
BAK_SOURCES="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../" && pwd )/"

# Logfile
# Redirect stdout & stderr to tmp logfile.
# Gets copied later to the destination directory.
log_file=${BAK_SOURCES}'_PUBS_/log/restore.log'
exec >  >(tee -a ${log_file})
exec 2> >(tee -a ${log_file} >&2)
exec 2>&1

# Get Ubuntu version
. /etc/lsb-release
# $DISTRIB_RELEASE
# Example to check if version >= 13.04
# echo "$DISTRIB_RELEASE > 13" | bc


# Hello World
########################################################################
echo "============================================================"
echo "= PUBS Recovery Console                                    ="
echo "============================================================"
echo ""
echo "This is the recovery console of PUBS."
echo "Please choose an option and press [Enter]"
echo ""
echo "(1): Recover files only" 
echo "(2): Full recovery"
echo ""
read userStep

case "${userStep}" in

"1")
	echo "> ------------------------------------"
	echo "> This will restore your backup files"
	echo ""
	pause "> Press [Enter] key to continue..."
	echo "> ------------------------------------"
	recover_files
	;;
"2") 
	echo "> ------------------------------------"
	echo "> This will restore the FULL system"
	echo ""
	pause "> Press [Enter] key to continue..."
	echo "> ------------------------------------"
	recover_system_package_configuration
	install_packages
	recover_files
	reboot
	;;
*)  
	echo "Invalid option!"
	exit; 
esac