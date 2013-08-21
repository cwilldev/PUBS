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

# Hello World
echo "============================================================"
echo "= Welcome to PUBS                                          ="
echo "= Pluginable Ubuntu Backup Suite v0.1                      ="
echo "=                                                          ="
echo "= This script comes with no warranty                       ="
echo "= [CTRL] + [Z] to kill process                             ="
echo "============================================================"
 

#####################################################################################
#
# VARIABLES
#
#####################################################################################

# PUBS root directory
PUBS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )/"

# Will contain all PUBS-entity files
declare -a entities
  
# This array will contain all source directories (configured within each entity file) 
# to be backed up.
declare -a source_directories 

# Array containing the individual arguments used for the rsync call.
# Each entity provides its own set of arguments.
declare -a rsync_args

# Will contain all users with a home directory (used for impersonification purposes)
declare -a home_users  

# Will contain the backup's target directory, as configured in the pubs.cfg file.
cfg_destination_directory='' 
  
# Will contain all enabled entities, as configured in the pubs.cfg file.
declare -a cfg_entities

# Will contain all enabled plugins, as configured in the pubs.cfg file.
declare -a cfg_plugins

# Will contain the date format, as configured in the pubs.cfg file.
cfg_date_format="+%Y-%m-%dT%H:%M:%S" # default

# Will contain the temporary log file (which gets copied to the destination directory 
# once the backup process is finished)
tmp_log_file=''

# We use the current date for each backup as sub-directory-name within the given 
# $cfg_destination_directory. This value gets set during the init-function.
date=''
 
 
#####################################################################################
#
# FUNCTIONS
#
#####################################################################################
 
# Include function library
source ${PUBS_PATH}lib/functions.sh

# Initialize basic variables.
# Read entities into scope.
#####################################################################################
function init() {

	# Config: Get destination directory
	cfg_destination_directory=$(grep -Po "(?<=^DESTINATION=).*" ${PUBS_PATH}pubs.cfg)
	
	# Config: Get entities as array
	tmpEntities=$(grep -Po "(?<=^ENTITIES=).*" ${PUBS_PATH}pubs.cfg)
	cfg_entities=(${tmpEntities//,/ })
	
	# Config: Get plugins as array
	tmpPlugins=$(grep -Po "(?<=^PLUGINS=).*" ${PUBS_PATH}pubs.cfg)
	cfg_plugins=(${tmpPlugins//,/ })
	
	# Config: Get date format
	cfg_date_format=$(grep -Po "(?<=^DATE_FORMAT=).*" ${PUBS_PATH}pubs.cfg)
	
	# Init date
	date=`date "${cfg_date_format}"` 
	
	# Logfile
	# Redirect stdout & stderr to tmp logfile.
	# Gets copied later to the destination directory.
	tmp_rand=$(cat /dev/urandom | tr -cd [:alnum:] | head -c 4)
	tmp_log_file="/tmp/pubs_"$date"_"$tmp_rand".log"
	exec >  >(tee -a ${tmp_log_file})
	exec 2> >(tee -a ${tmp_log_file} >&2)
	exec 2>&1

	# Get and set available user list to $home_users
	tmp_users="$( getent passwd | grep /home/ | cut -d ':' -f 1 )"
	for u in ${tmp_users}
	do
		tmp_dir="/home/${u}"
		if [ -d "$tmp_dir" ]; then
			home_users+=(${u})
		fi
	done	
		
	# Read entity files
	# Iterate only through entities that are enabled via configuration (pubs.cfg)
	for i in "${!cfg_entities[@]}"
	do
		# Entity files get used for rsync-exclude-from, so they must be remembered
		cur_entity_file=${PUBS_PATH}entities/${cfg_entities[i]}
		entities+=(${cur_entity_file}) 
		
		# Extract source directory
		sd_tmp=$(grep -Po "(?<=SOURCE_DIRECTORY).*" ${cur_entity_file})
		sd_tmp=$(echo ${sd_tmp} | sed -e 's/^ *//g' -e 's/ *$//g') # remove spaces
		source_directories+=(${sd_tmp})
		
		# Extract rsync arguments
		ra_tmp=$(grep -Po "(?<=RSYNC_ARGS).*" ${cur_entity_file})
		ra_tmp=$(echo ${ra_tmp} | sed 's/^ *//g') # remove leading spaces
		rsync_args+=("${ra_tmp}")
	done
}


# Validates all variables
#####################################################################################
function validate {
 
	# Check whether this script got called as super user. If not, we can not 
	# proceed.
	if [ "$(whoami)" != "root" ]; then
		failure 'Aborting: You must be root to execute this script.'
	fi

	# Check cfg_destination_directory to be valid
	if [ ! -d ${cfg_destination_directory} ]; then
		failure 'Aborting: Destination directory "'${cfg_destination_directory}'" does not exist. Maybe it is not mounted?'
	fi
 
	# Check for config files
	if [ ${#entities[@]} == 0 ]; then
		failure 'Aborting: No entities specified. Please enable at least one entity in the pubs.cfg to be backed up.'
	fi
	
	# Check if each config file contains the RSYNC_ARGS parameter
	if [ ${#entities[@]} != ${#rsync_args[@]} ]; then
		failure 'Aborting: Invalid entity file(s). Missing RSYNC_ARGS parameter.'
	fi
	
	# Check if each config file contains the SOURCE_DIRECTORY parameter
	if [ ${#entities[@]} != ${#source_directories[@]} ]; then
		failure 'Aborting: Invalid entity file(s). Missing SOURCE_DIRECTORY parameter.'
	fi
	
	# Check source directories to be valid
	for ((i=0;i<${#source_directories[@]};i++)); do
		if [ ! -d ${source_directories[i]} ]; then
			failure "Aborting: Source directory ${source_directories[i]} does not exist."
		fi
	done
}
 

#####################################################################################
#
# STARTUP
#
#####################################################################################

# We must be lord of the system
if [ "$(whoami)" != "root" ]; then
	echo 'Aborting: You must be root to execute this script.'
	exit 1
fi

# Do some basic initialization 
init

# Include all enabled plugins
includePlugins
fire_plugin_event "on_plugin_loaded"

# Validate environment
fire_plugin_event "before_validation"
validate 
fire_plugin_event "after_validation"
 
# The main symlink pointing to the latest (this) backup
latest_backup_dir=${cfg_destination_directory}/current

# The full path to the backup destination directory. Keep hierarchies.
current_bak_dest_dir=${cfg_destination_directory}/${date}/

# Do not set the link-dest argument on the first run, since there will be no 
# referencing sub-directories within the "latest backup" directory yet.
link_dest=''
if [ -e ${latest_backup_dir} ]
then 
	link_dest='--link-dest='${latest_backup_dir}/
fi

# The directory we will copy ourself into
script_dest_dir=${current_bak_dest_dir}_PUBS_/

# Display working target directory
output "= Timestamp:   ${date}"
output "= Destination: ${cfg_destination_directory}/${date}"
output "= Logfile:     ${script_dest_dir}backup.log"
output "============================================================"
  

#####################################################################################
#
# RSYNC
#
#####################################################################################
fire_plugin_event "before_process"

for ((i=0;i<${#source_directories[@]};i++)); do
	
	# Let the user know which entity we are currently processing
	output ""
	output "============================================================"
	output "= PROCESSING ENTITY #$(($i + 1)):"
	output "= File:   ${entities[i]} "
	output "= Source: ${source_directories[i]} "
	output "= Target: ${current_bak_dest_dir} "
	output "= Args:   ${rsync_args[i]} "
	output "============================================================"

	fire_plugin_event "on_process"
	
	# Call rsync - this is the main logic! 
	# link_dest             - Is only set if the initial backup was processed already
	# current_bak_dest_dir  - The backup location (of structure destination/date/hierarchy)
	# source_directories[i] - The current directory to be backed up
	# rsync_args[i] 		- Individual rsync arguments, defined in each entity-configuration
	rsync ${rsync_args[i]} --exclude-from ${entities[i]} ${link_dest} ${source_directories[i]} ${current_bak_dest_dir} 
 
done  
 
# Keep symlink up to date
if [ -e ${current_bak_dest_dir} ]
then
	rm -f ${latest_backup_dir} # Remove
	ln -s ${cfg_destination_directory}/${date} ${latest_backup_dir} # Re-create
fi 

fire_plugin_event "after_process"
 
 
#####################################################################################
#
# RESTORE PREPARATION
# 
# We copy all files that will be required during the recovery to the destination 
# folder as well.
#
#####################################################################################

fire_plugin_event "before_restore_preparation"

# Create directories
mkdir -p ${script_dest_dir} 
mkdir ${script_dest_dir}'restore'
mkdir ${script_dest_dir}'restore/apt'
mkdir ${script_dest_dir}'log'

# Export list of all installed applications and repository keys
apt_dir=${script_dest_dir}'restore/apt/'
cp /etc/apt/sources.list ${apt_dir}'sources.list'
if [ -f '/etc/apt/apt.conf' ]; then
   cp /etc/apt/apt.conf ${apt_dir}'apt.conf'
fi
if [ -f '/etc/apt/preferences' ]; then
	cp /etc/apt/preferences ${apt_dir}'preferences'
fi	
cp -R /etc/apt/sources.list.d/ ${apt_dir}
cp -R /etc/apt/apt.conf.d/ ${apt_dir}
cp -R /etc/apt/preferences.d/ ${apt_dir}
cp -R /var/lib/apt/lists/ ${apt_dir}

apt-key key exportall > ${script_dest_dir}'restore/repositories.keys'

# Solution 1: dpkg selectiom -> Buggy (as of 12.10), re-import won't work
dpkg --get-selections > ${script_dest_dir}'restore/installed-packages.lst' 

# Solution 2: apt-mark -> Buggy as well (as of 12.10)
apt-mark showauto > ${script_dest_dir}'restore/pkgs_auto.lst'
apt-mark showmanual > ${script_dest_dir}'restore/pkgs_manual.lst'

# Solution 3: Manual approach -> Create list of packages to re-install one by on recovery
package_list=$(dpkg-query -Wf '${Package} ')
package_list=${package_list// /$'\n'}  # change the semicolons to white space
for package in $package_list; do
	echo "$package" >> ${script_dest_dir}'restore/apt-install.lst'
done

# Copy tmp logfile to current destination directory
mv ${tmp_log_file} ${script_dest_dir}"log/backup.log"

# Copy script files to backup as well
cp -R ${PUBS_PATH}'app/' ${script_dest_dir}
cp -R ${PUBS_PATH}'tools/' ${script_dest_dir}
cp -R ${PUBS_PATH}'entities/' ${script_dest_dir}
cp -R ${PUBS_PATH}'plugins/' ${script_dest_dir} 
cp ${PUBS_PATH}"pubs.cfg" ${script_dest_dir}'/'

fire_plugin_event "after_restore_preparation"


#####################################################################################
#
# FINISH
#
#####################################################################################

output ""
output "============================================================"
output "= THAT'S IT - WE ARE DONE !"
output "============================================================"
	
fire_plugin_event "on_finish"