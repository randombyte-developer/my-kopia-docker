#!/bin/bash

while [[ "$#" -gt 0 ]]
	do
		case $1 in
			--source_server) source_server="$2"; shift;;
			--source_user) source_user="$2"; shift;;
			--source_pass) source_pass="$2"; shift;;
			--repo_pass) repo_pass="$2"; shift;;
			--target_server) target_server="$2"; shift;;
			--target_user) target_user="$2"; shift;;
			--target_pass) target_pass="$2"; shift;;
			--b2_reconnect_token) b2_reconnect_token="$2"; shift;;
		esac
	shift
done

if [[ -z $source_server ]]; then
	echo "--source_server SMB server must not be empty!"
	exit 1
fi

if [[ -z $source_user ]]; then
	echo "--source_user SMB user must not be empty!"
	exit 1
fi

if [[ -z $source_pass ]]; then
	echo "--source_pass SMB password must not be empty!"
	exit 1
fi

if [[ -z $repo_pass ]]; then
	echo "--repo_pass Repo password must not be empty!"
	exit 1
fi

echo "Mounting source SMB share $source_server"
mkdir /mnt/source
mount -t cifs $source_server /mnt/source -o username=$source_user,password=$source_pass

if [[ $target_server ]] && [[ $target_user ]] && [[ $target_pass ]]; then
	echo "Mounting target SMB share $target_server"
	mkdir /mnt/target
	# noserverino is necessary if a Fritzbox USB/NAS SMB share is used, otherwise there is an error "Stale file handle" when reading data
	mount -t cifs $target_server /mnt/target -o noserverino,username=$target_user,password=$target_pass

	#kopia start server 
fi
