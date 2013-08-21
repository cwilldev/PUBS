# Includes all enabled plugins.
#####################################################################################
function includePlugins() {
	for ((i=0;i<${#cfg_plugins[@]};i++)); do
		source ${PUBS_PATH}plugins/${cfg_plugins[i]}/plugin.sh
	done  
}


# Exits script with failure code 1 and displays a desktop notification of type "error" 
# as well.
#
# Args:
# $1 - String - Error message
#####################################################################################
function failure() {	
	echo $1
	display_notification "PUBS - Error occurred" "${1}" "dialog-error"
	fire_plugin_event "on_failure"
	exit 1 
}


# Prints message to stdout.
#
# Args:
# $1 - String - Message
#####################################################################################
function output() {
	echo $1
}


# Calls the event-handler of each plugin.
#
# Args
# $1 - String - Name of the event (ie on_process_start)
#####################################################################################
function fire_plugin_event() {
	for ((k=0;k<${#cfg_plugins[@]};k++)); do
		funcName=${cfg_plugins[k]}_$1
		#echo ${funcName}
		eval ${funcName}
	done  
} 