#!/bin/bash
 
# Copyright (c) 2013 Christopher Will<dev@cwill-dev.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of 
# this software and associated documentation files (the "Software, to deal in the 
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

#####################################################################################
#
# X-NOTIFY
# Adds KDE/GNOME/UNITY tray support for status messages to the backup process.
# If this plugin is enabled it informs the session of each logged in user about
# the process status.
#
# Notice: 
# For this to work the  notify-send package must be isntalled
#####################################################################################
 

#####################################################################################
#
# EVENT HANDLER
#
#####################################################################################

# Display X tray notification message once this plugin is loaded.
# Setting display properties for the desktop notifications as well.
function x_notify_on_plugin_loaded() { 

	# Display tray baloon
	process_start_date_time=`date "${cfg_date_format}"`
	display_notification "PUBS - Backup started" "Backup process started at ${process_start_date_time}"	
	
	# Setting display properties for the desktop notifications
	DISPLAY=":0.0"
	export DISPLAY
}
function x_notify_before_validation() {  	
	:
}
function x_notify_after_validation() { 
	: 
}
function x_notify_before_process() { 
	: 
}
function x_notify_on_process() { 
	: 
}
function x_notify_after_process() { 
	: 
}
function x_notify_before_restore_preparation() { 
	: 
}
function x_notify_after_restore_preparation() { 
	: 
}
# Display X tray notification message once the backup process is done
function x_notify_on_finish() { 

	# Notify UI (multiline intended)
	process_end_date_time=`date "${cfg_date_format}"`
	finish_msg="Backup process finished at ${process_end_date_time}

	Destination directory: ${current_bak_dest_dir}

	Logfile: ${script_dest_dir}log/backup.log"

	display_notification "PUBS - Backup finished" "${finish_msg}" "dialog-ok"
}
function x_notify_on_failure() { 
	: 
}
function x_notify_on_output() { 
	: 
}


#####################################################################################
#
# LOCAL FUNCTIONS
#
#####################################################################################

# Displays a notification baloon in desktop environment for each user.
#
# @required: notify-send to be installed
#
# Args
# 1 - String - Title
# 2 - String - Content
# 3 - String - System icon (ie dialog-ok, dialog-error, dialog-information etc)
#####################################################################################

function display_notification() {
	
	# Send UI-notification only if notify-send is installed
	notify_installed=$(which notify-send)
	if [ -n "$notify_installed" ]; then	
		
		icon_dialog="dialog-information"
		if [[ -n "$3" ]]; then
			icon_dialog=${3}
		fi  
		for ((dn_index=0;dn_index<${#home_users[@]};dn_index++)); do 
			$(su -c "notify-send -u critical \"${1}\" \"${2}\" --icon=${icon_dialog}" -s /bin/sh ${home_users[dn_index]})
		done  
		
	fi
} 