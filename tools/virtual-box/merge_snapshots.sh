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
echo '========================================'
echo '= THIS SCRIPT COMES WITH NO WARRANTY   ='
echo '= Bash version '${BASH_VERSION}'       ='
echo '= [CTRL] + [Z] to kill process         ='
echo '========================================'

# Exit with message and error code
function failure() {	
	echo ''
	echo 'ERROR:'$1
	echo ''
	exit 1
}

# Check whether this script got called as super user. If not, we can not 
# proceed.
if [ "$(whoami)" != "root" ]; then
	failure 'Aborting: You must be root to execute this script.'
fi
  
# Get all users
declare -a users 	
tmp_users="$( getent passwd | grep /home/ | cut -d ':' -f 1 )"
for u in ${tmp_users}; do
	tmp_dir="/home/${u}"
	if [ -d "$tmp_dir" ]; then
		users+=(${u})
	fi
done	

# Do delete/merge all snapshots
for ((i=0;i<${#users[@]};i++)); do

	echo "> Processing user: ${users[i]}"

	# Get all installed VMs
	vms=$(su -c "VBoxManage list vms | sed -E 's/^\"(.*)\".*/\1/g'" -s /bin/sh ${users[i]})

	# Create new snapshot of each
	for vm_name in $vms; do 
		
		echo "> > Processing VM ${vm_name}.."

		# Loop through each snapshot and delete/merge it
		snapshots=$(su -c "VBoxManage showvminfo ${vm_name} --machinereadable | grep SnapshotName | cut -d '\"' -f2" -s /bin/sh ${users[i]})
		for snapshot_name in $snapshots; do 
			echo "> > > Merging snapshot: ${snapshot_name}.."
			snapshots=$(su -c "VBoxManage snapshot ${vm_name} delete ${snapshot_name}" -s /bin/sh ${users[i]})
		done
	done
	
done