#!/bin/bash

action=$1

# SCRIPT CONFIGURATION

# Mounted drives configuration
user="sambausername" # (Username, Group) owner of the mounted drives
group="sambausername"
enc_path="/boxes/.box_enc" # Location of the encrypted directory
clear_path="/boxes/box" # Location of the readble directory
access_mode=777
extpass_script="/path/.extpass_script.sh" # Location of the extpass script (script contains: echo "password to encrypt the distant drive")

# Distant access configuration
distant_user="scpuser" # Username to log-on distant server
distant_host="distant" # Hostname or IP address of distant server (owning encrypted data)
distant_path="box" # Path of encrypted directory (encfs one) on distant machine (relative or absolute)
distant_ip="000.000.000.000" # IP of distant server

# Local configuration
local_gateway_ip="192.168.0.1" # IP address of the local gateway
local_interface="eth0" # Interface to reach the local network

# SCRIPT WARM-UPS

uid=$(cat /etc/passwd | grep $user | cut -d: -f3)
gid=$(cat /etc/group | grep $group | cut -d: -f3)

# HELPERS

# Display helpers

function echo_error()
{
	echo -e "\033[0;31m$1\033[0m"
}
function echo_warning()
{
	echo -e "\033[0;33m$1\033[0m"
}
function echo_success()
{
	echo -e "\033[0;32m$1\033[0m"
}
function echo_info()
{
	echo -e "\033[0;36m$1\033[0m"
}

# Start helpers

function create_enc()
{
	echo -n "."
	mkdir -p "${enc_path}"

	echo -n "."
	chown "${user}:${group}" "${enc_path}"
	if [ $? -ne 0 ]; then
		echo_error "Unable to change the owner of the encrypted directory: ${enc_path}"
		return 201
	fi

	echo -n "."
	chmod "${access_mode}" "${enc_path}"
	if [ $? -ne 0 ]; then
		echo_error "Unable to change the file mode of encrypted directory: ${enc_path}"
		return 202
	fi
	return 0
}

function mount_enc()
{
	echo -n "."
	sshfs "${distant_user}@${distant_host}:${distant_path}" "${enc_path}" -o reconnect -o "uid=${uid}" -o "gid=${gid}"
	if [ $? -ne 0 ]; then
		echo_error "Unable to mount encrypted directory: ${distant_user}@${distant_host}:${distant_path} into ${enc_path}"
		return 203
	fi
	return 0
}

function create_clear()
{
	echo -n "."
	mkdir -p "${clear_path}"

	echo -n "."
	chown "${user}:${group}" "${clear_path}"
	if [ $? -ne 0 ]; then
		echo_error "Unable to change the owner of the readable directory: ${clear_path}"
		return 101
	fi

	echo -n "."
	chmod "${access_mode}" "${clear_path}"
	if [ $? -ne 0 ]; then
		echo_error "Unable to change the file mode of readable directory: ${clear_path}"
		return 102
	fi
	return 0
}

function mount_clear()
{
	echo -n "."
	encfs --extpass="${extpass_script}" --public "${enc_path}" "${clear_path}" -o "uid=${uid}" -o "gid=${gid}"
	if [ $? -ne 0 ]; then
		echo_error "Unable to mount readable directory"
		return 204
	fi
	return 0
}

function start_samba()
{
	echo -n "."
	/usr/sbin/service smbd start
	return 0
}

# Status helpers

function readd_missing_routes()
{
	ret=$(/sbin/ip route show | grep "${distant_ip} via ${local_gateway_ip} dev ${local_interface}" | wc -l)
	if [ "$ret" -gt 0 ]; then
		echo_info "Route towards server: OK"
	else
		echo_warning "Route towards server: RE-ADDED"
		ip route add "${distant_ip}" dev "${local_interface}" via "${local_gateway_ip}"
	fi
	return 0
}

function status_enc()
{
	ret=$(cat /proc/mounts | grep "${enc_path}" | wc -l)
	if [ "$ret" -gt 0 ]; then
		echo_info "Encoded directory: OK"
	else
		echo_warning "Encoded directory: DOWN"
		return 1
	fi

	ret=$(timeout 60 ls -alh "${enc_path}")
	if [ $? -eq 0 ]; then
		echo_info "Encoded directory accessible: OK"
	else
		echo_warning "Encoded directory accessible: DOWN -- TIMEOUT"
		return 11
	fi
	return 0
}

function status_clear()
{
	ret=$(cat /proc/mounts | grep "${clear_path}" | wc -l)
	if [ "$ret" -gt 0 ]; then
		echo_info "Readable directory: OK"
	else
		echo_warning "Readable directory: DOWN"
		return 2
	fi

	ret=$(timeout 60 ls -alh "${clear_path}")
	if [ $? -eq 0 ]; then
		echo_info "Readable directory accessible: OK"
	else
		echo_warning "Readable directory accessible: DOWN -- TIMEOUT"
		return 12
	fi
	return 0
}

function status_samba()
{
	ret=$(/usr/sbin/service smbd status)
	if [ $? -eq 0 ]; then
		echo_info "Samba: OK"
	else
		echo_warning "Samba: DOWN"
		return 3
	fi
	return 0
}

# Restart helpers

function restart_samba()
{
	/usr/sbin/service smbd restart
	return 0
}

# Stop helpers

function del_enc()
{
	echo -n "."
	rmdir "${enc_path}"
	if [ $? -ne 0 ]; then
		echo "Failed to delete encrypted directory"
		return 21
	fi
	return 0
}

function stop_enc()
{
	echo -n "."
	fusermount -u "${enc_path}"
	if [ $? -ne 0 ]; then
		echo "Failed to unmount encrypted directory"
		return 20
	fi
	return 0
}

function force_stop_enc()
{
	echo -n "."
	fuser -k "${enc_path}"
	if [ $? -ne 0 ]; then
		echo "Failed to force unmount encrypted directory"
		return 20
	fi
	return 0
}

function del_clear()
{
	echo -n "."
	rmdir "${clear_path}"
	if [ $? -ne 0 ]; then
		echo_error "Failed to delete readable directory"
		return 11
	fi
	return 0
}

function stop_clear()
{
	echo -n "."
	fusermount -u "${clear_path}"
	if [ $? -ne 0 ]; then
		echo_error "Failed to unmount readable directory"
		return 10
	fi
	return 0
}

function force_stop_clear()
{
	echo -n "."
	fuser -k "${clear_path}"
	if [ $? -ne 0 ]; then
		echo_error "Failed to unmount readable directory"
		return 10
	fi
	return 0
}

function stop_samba()
{
	echo -n "."
	/usr/sbin/service smbd stop
	if [ $? -ne 0 ]; then
		echo_error "Failed to stop Samba server"
		return 1
	fi
	return 0
}

# ACTIONS

function runner()
{
	case $1 in
		start)
			readd_missing_routes && \
			echo_info "Mounting distant drives" && \
				create_enc && mount_enc && \
				create_clear && mount_clear && \
			echo_info "Starting Samba server" && \
				start_samba

			local value=$?
			if [ $value -eq 0 ]; then
				echo_success "Service started successfully"
			else
				echo_error "Service have not been started correctly"
			fi
			return $value
			;;

		force-start)
			readd_missing_routes && \
			echo_info "Mounting distant drives" && \
				( status_enc || ( create_enc && mount_enc ) ) && \
				( status_clear || ( create_clear && mount_clear ) ) && \
			echo_info "Starting Samba server" && \
				( ( status_samba && restart_samba ) || start_samba )
			
			local value=$?
			if [ $value -eq 0 ]; then
				echo_success "Service started successfully"
			else
				echo_error "Service have not been started correctly"
			fi
			return $value
			;;

		stop)
			echo_info "Stopping Samba server in order to unlock shared drives" && \
				stop_samba && \
			echo_info "Unmounting distant drives" && \
				stop_clear && del_clear && \
				stop_enc && del_enc

			local value=$?
			if [ $value -eq 0 ]; then
				echo_success "Service stopped successfully"
			else
				echo_error "Service have not been stopped correctly"
			fi
			return $value
			;;

		force-stop)
			echo_info "Stopping Samba server in order to unlock shared drives" && \
				( ! status_samba || stop_samba ) && \
			echo_info "Unmounting distant drives" && \
				( ! status_clear || stop_clear || force_stop_clear ) && ( del_clear || true ) && \
				( ! status_enc || stop_enc || force_stop_enc ) && ( del_enc || true )

			local value=$?
			if [ $value -eq 0 ]; then
				echo_success "Service stopped successfully"
			else
				echo_error "Service have not been stopped correctly"
			fi
			return $value
			;;

		status)
			readd_missing_routes && \
			echo_info "Checking status" && \
				status_enc && \
				status_clear && \
				status_samba

			local value=$?
			if [ $value -eq 0 ]; then
				echo_success "Service is UP"
			else
				echo_error "Service is DOWN"
			fi
			return $value
			;;

		*)
			echo_error "Unknown action :: $1"
			return -1
			;;
	esac
}

case $action in
	restart)
		runner "stop" && \
		runner "start"
		;;
	force-restart)
		runner "force-stop" && \
		runner "force-start"
		;;
	*)
		runner "${action}"
		;;
esac

exit $?
