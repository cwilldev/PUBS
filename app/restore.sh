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

# Functions
########################################################################
	
# Helper method to request user interaction
# Args
# 1: Message to display
function pause() {
   read -p "$*"
}


# Initialization
########################################################################

# We must be lord of the system
if [ "$(whoami)" != "root" ]; then
	echo 'Aborting: You must be root to execute this script.'
	exit 1
fi

# Root directory of the backedup files (per definition two levels up)
BAK_SOURCES="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../" && pwd )/"


# Hello World
########################################################################
echo "============================================================"
echo "= PUBS Recovery Console                                    ="
echo "============================================================"
echo ""
echo "This is the recovery console of PUBS."
echo "The script will guide you step by step through the recovery."
echo ""
echo "Step 1: Replace package information"
echo "Step 2: Add repository keys"
echo "Step 3: Update source lists"
echo "Step 4: Restore and install packages"
echo "Step 5: Restore system"
echo "Step 6: Reboot"
echo ""
echo "Good luck my friend - may the force be with you!"
echo "------------------------------------------------------------"
echo ""

pause "> Press [Enter] key to continue..."

echo ""
echo "============================================================"
echo "ATTENTION ! ATTENTION ! ATTENTION ! ATTENTION ! ATTENTION"
echo ""
echo "Continuing recovery may harm your computer if done "
echo "unintentionnaly or on wrong device."
echo ""
echo "Please double check if this is what you want to do!"
echo "============================================================"
echo ""

pause "> Press [Enter] key to continue..."


# Replace local package sources information with our backup
########################################################################
echo ""
echo "> ------------------------------------"
echo "> 1/6: Replace package information"
echo "> ------------------------------------"
echo ""
pause "> Press [Enter] key to continue..."
BAK_APT_DIR=${BAK_SOURCES}'_PUBS_/restore/apt/'
cp ${BAK_APT_DIR}'sources.list' /etc/apt/sources.list
if [ -f ${BAK_APT_DIR}'apt.conf' ]; then
	cp ${BAK_APT_DIR}'apt.conf' /etc/apt/apt.conf 
fi
if [ -f ${BAK_APT_DIR}'preferences' ]; then
	cp ${BAK_APT_DIR}'preferences' /etc/apt/preferences
fi
cp -R ${BAK_APT_DIR}sources.list.d/ /etc/apt/sources.list.d/ 
cp -R ${BAK_APT_DIR}apt.conf.d/ /etc/apt/apt.conf.d/
cp -R ${BAK_APT_DIR}preferences.d/ /etc/apt/preferences.d/
cp -R ${BAK_APT_DIR}lists/ /var/lib/apt/lists/
echo ""
echo "> [DONE]" 
echo "" 


# Add repository keys to system
########################################################################
echo ""
echo "> ------------------------------------"
echo "> 2/6: Add repository keys"
echo "> ------------------------------------"
echo ""
pause "> Press [Enter] key to continue..."
apt-key add ${BAK_SOURCES}_PUBS_/restore/repositories.keys
echo "> [DONE]" 
echo ""


# Update the sources list
########################################################################
echo ""
echo "> ------------------------------------"
echo "> 3/6: Update and upgrade packages"
echo "> ------------------------------------"
echo ""
pause "> Press [Enter] key to continue..."
apt-get update
apt-get -y upgrade 
echo "> [DONE]" 
echo ""


# Restore backuped packages
########################################################################
echo ""
echo "> ------------------------------------"
echo "> 4/6: Restore packages (long process)"
echo "> ------------------------------------"
echo ""
pause "> Press [Enter] key to continue..."

# Solution 1: dpkg selection
# Damn dpkg.. too bugy to use this simple stuff!
#dpkg --clear-selections
#dpkg --set-selections < ${BAK_SOURCES}_myback_/restore/installed-packages.lst 
#apt-get update
#apt-get dselect-upgrade

# Solution 2: apt-mark
# Damn apt-mark
#apt-mark auto $(cat ${BAK_SOURCES}_myback_/restore/pkgs_auto.lst)
#apt-mark manual $(cat ${BAK_SOURCES}_myback_/restore/pkgs_manual.lst)

# Solution 3: Manual install packages one-by-one
while read p; do
	if [[ -n "$p" ]]; then
		
		echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
		echo "> "${p}
		echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

		apt-get -y install $p
	fi
done < ${BAK_SOURCES}_PUBS_/restore/apt-install.lst

# Remove unneeded packages
apt-get -y autoremove

echo "> [DONE]" 
echo ""


# Copy backup
########################################################################
echo ""
echo "> ------------------------------------"
echo "> 5/6: Restore system (long process)"
echo "> ------------------------------------"
echo ""
pause "> Press [Enter] key to continue..."
rsync -av --exclude="/_PUBS_/" ${BAK_SOURCES} /
echo "> [DONE]" 
echo ""

# Reboot
########################################################################
echo ""
echo "> ------------------------------------"
echo "> 6/6: Reboot"
echo "> ------------------------------------"
echo ""
echo "Awesome! We are done."
echo "Hope to see you back after reboot :-)"
echo ""
pause "> Press [Enter] key to finish!"
reboot
echo "> [DONE]"