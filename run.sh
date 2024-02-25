#!/bin/bash

# General
kopia_ui_user="${KOPIA_UI_USER}"
source_server="${SOURCE_SERVER}"
source_user="${SOURCE_USER}"

# For SMB targets
target_server="${TARGET_SERVER}"
target_user="${TARGET_USER}"

# For B2 targets
b2_bucket_name="${B2_BUCKET_NAME}"
max_upload_speed="${MAX_UPLOAD_SPEED}"
max_download_speed="${MAX_DOWNLOAD_SPEED}"

declare -A secrets

# General
secrets[kopia_ui_pass]=KOPIA_UI_PASS
secrets[source_pass]=SOURCE_PASS
secrets[repo_pass]=REPO_PASS

# For SMB targets
secrets[target_pass]=TARGET_PASS

# For B2 targets
secrets[b2_key_id]=B2_KEY_ID
secrets[b2_key]=B2_KEY

# Read secrets
for secret_variable_name in ${!secrets[@]}; do
	declare -n secret_variable=$secret_variable_name
	secret_name=secrets[${key}]
	secret_path="/run/secrets/$secret_name"
	if [[ -f "$secret_path" ]]; then
		echo "Reading $secret_variable_name from $secret_path"
		secret_variable=$(<"$secret_path")
	fi
done

# Passing parameters via command line should only be used during development
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
			--b2_key_id) b2_key_id="$2"; shift;;
			--b2_key) b2_key="$2"; shift;;
			--max_upload_speed) max_upload_speed="$2"; shift;;
			--max_download_speed) max_download_speed="$2"; shift;;
		esac
	shift
done

required_parameters=(
	kopia_ui_user
	kopia_ui_pass
	source_server
	source_user
	source_pass
	repo_pass
)
for parameter in "${required_parameters[@]}"; do
	if [[ -z ${!parameter} ]]; then
		echo "Parameer $parameter must not be empty!"
		exit 1
	fi
done

echo "Mounting source SMB share $source_server readonly"
mkdir /mnt/source
mount -t cifs $source_server /mnt/source -o ro,username=$source_user,password=$source_pass
echo "Listing files in /mnt/source"
ls /mnt/source

common_repo_parameters=("--override-hostname=kopia" "--override-username=kopia" "--password=$repo_pass")
common_server_parameters=("--insecure" "--address=0.0.0.0:51515" "--server-username=$kopia_ui_user" "--server-password=$kopia_ui_pass")

if [[ $target_server ]] && [[ $target_user ]] && [[ $target_pass ]]; then
	echo "Mounting target SMB share $target_server"
	mkdir /mnt/target
	# noserverino is necessary if a Fritzbox USB/NAS SMB share is used, otherwise there is an error "Stale file handle" when reading data
	mount -t cifs $target_server /mnt/target -o noserverino,username=$target_user,password=$target_pass
	
	echo "Listing files in /mnt/target"
	ls /mnt/target

	echo "Connecting to repo at /mnt/target"
	kopia repository connect filesystem "${common_repo_parameters[@]}" --path=/mnt/target 
	echo "Starting server"
	kopia server start "${common_server_parameters[@]}"  
elif [[ $b2_bucket_name ]] && [[ $b2_key_id ]] && [[ $b2_key ]]; then
	echo "Connecting to B2 repo"
	kopia repository connect from-config "${common_repo_parameters[@]}" --bucket=$b2_bucket_name --key-id=$b2_key_id --key=$b2_key
	if [[ -n $max_upload_speed ]]; then
		echo "Setting max upload speed to $max_upload_speed"
		kopia repository throttle set --upload-bytes-per-second=$max_upload_speed
	fi
	if [[ -n $max_download_speed ]]; then
		echo "Setting max download speed to $max_download_speed"
		kopia repository throttle set --download-bytes-per-second=$max_download_speed
	fi
	echo "Starting server"
	kopia server start "${common_server_parameters[@]}"
else
	echo "No target SMB share or B2 bucket given. Exiting."
	exit 1
fi
