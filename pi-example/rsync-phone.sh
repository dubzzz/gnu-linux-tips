#!/bin/sh

backupdir=$(date +%d%m%Y-%H%M%S)

## PLEASE DEFINE THE FOLLOWING VARIABLES
## & EDIT THE run_sync COMMANDS AT THE BOTTOM OF THE FILE
username="<username to log onto the distant machine>"
hostname="<ip or hostname of the distant machine>"
dest="<destination of the backup on the distant machine>"

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
function echo_details()
{
   echo -e "\033[0;37m$1\033[0m"
}

function run_sync()
{
   path_src=$1                                   #eg.: /sdcard/DCIM
   path_dst=$2                                   #eg.: /boxes/sdcard

   path_cwd=$(pwd)
   log_rsync=$(echo "${path_src}.rlog" | sed "s/\//./g")
   log_find_out=$(echo "${path_src}.fout" | sed "s/\//./g")

   rm -f "${log_rsync}"
   rm -f "${log_find_out}"
   rm -f "${log_rsync}.2"
   rm -f "${log_find_out}.2"

   echo_info ":::  Run synchronisation for ${path_src} -> ${path_dst}  :::"
   echo_details "  :  RSYNC log file: ${path_cwd}/${log_rsync}"

   ifconfig | grep tun0 && rsync -e ssh -zz -v -b -rtgoDi --remove-source-files --log-file="${log_rsync}" --backup-dir="${path_dst}-${backupdir}" --exclude '.*' --exclude '*thumbnail*' "${path_src}" "${username}@${hostname}:${path_dst}/" > /dev/null 2>&1
   rsync_status=$?

   echo_details "  :  FIND stdout log file: ${path_cwd}/${log_find_out}"
   find "${path_src}/" -type f ! -name ".*" ! -path "*thumbnail*" > "${log_find_out}"

   echo_info ":::  Analysing synchronisation status  :::"
   cat "${log_rsync}" | sed -rn "s/^.*rsync: sender failed to remove (.+): Permission denied \(13\)$/\1/p" | sort > "${log_rsync}.2"
   cat "${log_find_out}" | cut -c 3- | cut -c "${#path_src}-" | sort > "${log_find_out}.2"

   diff "${log_rsync}.2" "${log_find_out}.2" > /dev/null 2>&1
   clean_status=$?

   if [ $rsync_status -ne 0 ]; then
      echo_details "Failure during the copy of ${path_src}"
      if [ $clean_status -ne 0 ]; then
         echo_error "Copy of some files seem to have failed"
      else
         echo_success "All your files have been copied successfully"
         echo_warning "Remove the remaining files in ${path_src} manually"
      fi
   else
      echo_success "Copy successful for ${path_src}"
   fi
   echo ""
}

function clean_empty()
{
   echo_info ":::  Clean empty directories  :::"
   ssh "${username}@${hostname}" "find ${dest}/ -empty -type d -depth -maxdepth 1 -exec rmdir {} \\;"
   echo ""
}

run_sync "/sdcard/DCIM" "${dest}/sdcard"
run_sync "/sdcard/Snapchat" "${dest}/sdcard"
run_sync "/storage/3502-1AE6/DCIM" "${dest}/sdcard1"
run_sync "/storage/3502-1AE6/Pictures" "${dest}/sdcard1"

clean_empty
