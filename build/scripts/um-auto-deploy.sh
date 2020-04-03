#!/bin/sh
## This script is used to synchronize documents with provider (Broker or Universal Messaging)
## The following variables need to be set before running the script, otherwise default values will be used instead :
### IS_PROTOCOL    : Integration server protocol (default : http)
### IS_HOST        : Integration server host (default : localhost)
### IS_PORT        : Integration server port (default : 5555)
### IS_USER        : Integration server user (default : Administrator)
### IS_PWD         : Integration server password (default : manage)
############# Function check environment variables ##############

check_variables() {

if [ -z "$IS_PROTOCOL" ]; then
    echo "# IS_PROTOCOL environment variable is not defined, using default value localhost"
    IS_PROTOCOL="http"
fi

if [ -z "$IS_HOST" ]; then
    echo "# IS_HOST environment variable is not defined, using default value localhost"
    IS_HOST="localhost"
fi

if [ -z "$IS_PORT" ]; then
    echo "# IS_PORT environment variable is not defined, using default value 5555"
    IS_PORT="5555"
fi

if [ -z "$IS_USER" ]; then
    echo "# IS_USER environment variable is not defined, using default value Administrator"
    IS_USER="Administrator"

fi

if [ -z "$IS_PWD" ]; then
    echo "# IS_PWD environment variable is not defined, using default value manage"
    IS_PWD="manage"
fi


}

############# Function sync document types ##############
sync_docs_provider() {

status=`curl -s -o /dev/null -w "%{http_code}" -u $IS_USER:$IS_PWD $IS_PROTOCOL://$IS_HOST:$IS_PORT/invoke/wx.msr.pub/syncDocsToProvider`

cmdret=$?
if [[ $cmdret != 0 || "$status" != "200" ]]
then
  echo "Failed failed to synchronize documents with provider error code : $status"
  exit 1
fi
 
}


main() {
	
	base_directory=$(dirname "$0")
	# Set log file 
	log_file="${base_directory}/um_auto_deploy.log"
	
	if [ ! -f "$log_file" ];
	then
		# Check and set environment variables
		check_variables >> ${log_file}
		# Synchronize documents with provider
		sync_docs_provider >> ${log_file}
	else
		# Nothing to do...
		echo "File ${log_file} exists, already deployed"
		exit 0
	fi
}

main $*