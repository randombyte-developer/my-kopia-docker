#!/bin/bash

kopia_ui_user="${KOPIA_UI_USER}"
source_server="${SOURCE_SERVER}"
source_user="${SOURCE_USER}"
target_server="${TARGET_SERVER}"
target_user="${TARGET_USER}"

if [[ -n "${KOPIA_UI_PASS_SECRET_PATH}" ]]; then
	echo "Reading kopia_ui_pass from ${KOPIA_UI_PASS_SECRET_PATH}"
	kopia_ui_pass=$(<"${KOPIA_UI_PASS_SECRET_PATH}")
fi

if [[ -n "${SOURCE_PASS_SECRET_PATH}" ]]; then
	echo "Reading source_pass from ${SOURCE_PASS_SECRET_PATH}"
	source_pass=$(<"${SOURCE_PASS_SECRET_PATH}")
fi

if [[ -n "${REPO_PASS_SECRET_PATH}" ]]; then
	echo "Reading repo_pass from ${REPO_PASS_SECRET_PATH}"
	repo_pass=$(<"${REPO_PASS_SECRET_PATH}")
fi

if [[ -n "${TARGET_PASS_SECRET_PATH}" ]]; then
	echo "Reading target_pass from ${TARGET_PASS_SECRET_PATH}"
	target_pass=$(<"${TARGET_PASS_SECRET_PATH}")
fi

if [[ -n "${B2_RECONNECT_TOKEN_SECRET_PATH}" ]]; then
	echo "Reading b2_reconnect_token from ${B2_RECONNECT_TOKEN_SECRET_PATH}"
	b2_reconnect_token=$(<"${B2_RECONNECT_TOKEN_SECRET_PATH}")
fi

while [[ "$#" -gt 0 ]]
	do
		case $1 in
			--kopia_ui_user) kopia_ui_user="$2"; shift;;
			--kopia_ui_pass) kopia_ui_pass="$2"; shift;;
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

if [[ -z $kopia_ui_user ]]; then
	echo "--kopia_ui_user Kopia UI user must not be empty!"
	exit 1
fi

if [[ -z $kopia_ui_pass ]]; then
	echo "--kopia_ui_pass Kopia UI password must not be empty!"
	exit 1
fi

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
mount -t cifs $source_server /mnt/source -o ro,username=$source_user,password=$source_pass
echo "Listing files in /mnt/source"
ls /mnt/source

if [[ $target_server ]] && [[ $target_user ]] && [[ $target_pass ]]; then
	echo "Mounting target SMB share $target_server"
	mkdir /mnt/target
	# noserverino is necessary if a Fritzbox USB/NAS SMB share is used, otherwise there is an error "Stale file handle" when reading data
	mount -t cifs $target_server /mnt/target -o noserverino,username=$target_user,password=$target_pass
	
	echo "Listing files in /mnt/target"
	ls /mnt/target

	kopia repository connect filesystem --path=/mnt/target --override-hostname=kopia --override-username=kopia --password=$repo_pass
	kopia server start --insecure --address=0.0.0.0:51515 --server-username=kopia --server-password=kopia
elif [[ $b2_reconnect_token ]]; then
	kopia repository connect from-config --token=$b2_reconnect_token --override-hostname=kopia --override-username=kopia
	kopia server start --insecure --address=0.0.0.0:51515 --server-username=kopia --server-password=kopia
else
	echo "No target SMB share or B2 bucket given. Exiting."
	exit 1
fi
