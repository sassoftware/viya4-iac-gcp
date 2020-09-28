#!/usr/bin/env bash

yum -y install nfs-utils

#
# create mount directory
#
mkdir -p /mnt/viya-share

#
# fstab entry
#
echo "${rwx_filestore_endpoint}:${rwx_filestore_path}    /mnt/viya-share    nfs    _netdev,auto,x-systemd.automount,x-systemd.mount-timeout=10,timeo=14,x-systemd.idle-timeout=1min,relatime,hard,rsize=65536,wsize=65536,vers=3,tcp,namlen=255,retrans=2,sec=sys,local_lock=none 0 0" >>/etc/fstab
#
# mount the nfs
#
systemctl enable NetworkManager-wait-online.service
mount -a

#
# Change permissions and owener
#
chmod 777 /mnt/viya-share -R
chown -R nobody:nobody /mnt/viya-share
