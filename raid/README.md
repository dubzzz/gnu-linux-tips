# RAID

Motherboard RAID sucks, software RAID is far better for personal usage and small structures.
This section will only discuss mdadm solution which is a software RAID tools.
It supports multiple kind of RAID, ranging from RAID-0 to RAID-6 or more exotic ones.

## Warm-up: Manage partitions

Manage partitions. You may want to refer to [MBR](https://github.com/dubzzz/gnu-linux-tips/tree/master/mbr) before applying any changes to partitions.
```bash
root@server: fdisk -L #list partitions and disks
root@server: fdisk /dev/sdX #change a partition
root@server: sfdisk -d /dev/sdb | sfdisk /dev/sdc #copy sdb partition table to sdc
```

## Configure RAID-1

Setup mdadm
```bash
root@server: apt-get install mdadm
```

Create RAID
```bash
root@server: mdadm --create --verbose /dev/md1 --level=1 --raid-devices=2 /dev/sdb1 /dev/sdc1
```
You can use _missing_ instead of any /dev/sdX if a disk is missing.
Safety disks can also be configured by addind _--spare=1_ to the command.

Watch RAID status
```bash
root@server: cat /proc/mdstat
root@server: watch -n 1 cat /proc/mdstat
```

Format array
```bash
root@server: mkfs.ext4 /dev/md1
```

Save configuration for next restart
```bash
root@server: mdadm --detail --scan --verbose > /etc/mdadm/mdadm.conf
```
This command must be run after every modification of the RAID structure or definition.

Edit /etc/fstab to mount the RAID automatically. Prefer using UUID when mounting disks in fstab. This technique is safer than specifying the name because it can changed whereas UUID cannot.
```bash
root@server: ls -l /dev/disk/by-uuid/
```

Check partition status by checking the file /proc/mdstat.
Using smartctl can help you to prevent disk failures.
