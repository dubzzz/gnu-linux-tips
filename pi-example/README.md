# Example of Raspberry PI configuration

## Bye-bye to your internet provider DNS

Edit /etc/resolv.conf:
```bash
nameserver 208.67.222.222
nameserver 208.67.222.220
```

Then run the following command to block the modification of the file:
```bash
root@pi:~$ chattr +i /etc/resolv.conf
```

It will block all future modification of the file until someone run the command with -i on this file.

If your server has a static IP address, you might want to add its IP address to known hosts of your machine. Do do that edit the file /etc/hosts and add the line:
```bash
xxx.yyy.zzz.ttt domain.ext
```
Where xxx.yyy.zzz.ttt is the static IP of the server and domain.ext its name.

### 

## Remote storage as local network drive

In that section, Raspberry PI can be seen as an always running machine without lots of storage.
This configuration can apply to all devices not having lots of storage but running all day long so that they can be used by all running machines of the local network and eventually machines outside of the network.

### Local drive

The idea is to build a safe remote drive accessible easily as a network drive from Windows, GNU/Linux or Mac.
It should be accessible from multiple instances implementing the following configuration.

It uses the Raspberry PI as a gateway for accessing encrypted remote data.

The real drive has been configured on a remote machine in order to be able to share it between multiple networks.
In my case, this drive is stored on a Kimsufi of OVH so it will be accessible whenever I need it.
The encrypted-side is to be sure that even if the remote machine was compromised it will not leak data so easily.

The setups of this configuration is described at:
https://github.com/dubzzz/gnu-linux-tips/blob/master/remote-storage/README.md

### Extended local network

But this configuration has some limitations:
- What if I want to access my data from another location outside of the local network?
- What if I want to access it from my mobile?

For security reasons, the unencrypted version must not be hold on the remote machine.
Otherwise it would have meant nothing to encrypt it, as it will not protect againt compromised machine.

Available choices:
- OpenVPN server on the PI
- OpenVPN server on remote and sharing Pi's (and all local) network drives to remote

#### OpenVPN Setup

OpenVPN installation is described at:
https://github.com/dubzzz/gnu-linux-tips/blob/master/openvpn/README.md

Close all traffic coming from OpenVPN network by default.

#### FTP Setup

FTP installation is described at:
https://github.com/dubzzz/gnu-linux-tips/blob/master/ftp/README.md#basic-ftp

I personally chose to use the same user for both samba and ftp. I also advise you to add the following options to Pure-FTPd for a safer configuration:
```bash
root@pi:~$ echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
root@pi:~$ echo "yes" > /etc/pure-ftpd/conf/NoAnonymous
root@pi:~$ echo "yes" > /etc/pure-ftpd/conf/NoChmod
root@pi:~$ echo "40000 40500" > /etc/pure-ftpd/conf/PassivePortRange
root@pi:~$ echo "113 002" > /etc/pure-ftpd/conf/Umask #file=664/folder=775 for consitency with samba
```

Don't forget to restart pure-ftpd service after any modifications of its configuration using:
```bash
root@pi:~$ service pure-ftpd restart
```

#### Restrict FTP to OpenVPN users

There is no need to expose FTP to users outside of the VPN. Users in local network will have a network drive shared using Samba, users outside of the network should not be granted any accesses except when connecting in the provided VPN.

Moreover, FTP is too usesafe to be exposed to external clients.

## Firewall configuration

For higher security in both local and vpn networks I suggest to increase firewall protection on the PI itself.
Please run these commands carefully as they may block access to some of the running services.

```bash
root@pi:~$ # Flush input rules, apply drop policy on inputs, do not kill exitsing connections and allow internal loop
root@pi:~$ iptables -F INPUT ; iptables -P INPUT DROP ; iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT ; iptables -I INPUT -i lo -j ACCEPT
root@pi:~$ # Apply accept policy on outputs and forward
root@pi:~$ iptables -P OUTPUT DROP ; iptables -P FORWARD DROP
root@pi:~$ # Allow ping from all interfaces (eth0, tun0...)
root@pi:~$ iptables -A INPUT -p icmp -j ACCEPT
root@pi:~$ # Limit SSH access to local network (on eth0 only) and VPN root server
root@pi:~$ iptables -A INPUT -p tcp -i eth0 --dport ssh -j ACCEPT
root@pi:~$ iptables -A INPUT -p tcp -i tun0 -s 10.8.0.1 --dport ssh -j ACCEPT
root@pi:~$ # Limit FTP access to VPN users only
root@pi:~$ iptables -A INPUT -p tcp -i tun0 -s 10.8.0.0/24 --dport ftp -j ACCEPT
root@pi:~$ iptables -A INPUT -p tcp -i tun0 -s 10.8.0.0/24 --dport 40000:40500 -j ACCEPT
root@pi:~$ # Limit Samba access to local network
root@pi:~$ iptables -A INPUT -p tcp -i eth0 --dport 137 -j ACCEPT
root@pi:~$ iptables -A INPUT -p udp -i eth0 --dport 138 -j ACCEPT
root@pi:~$ iptables -A INPUT -p udp -i eth0 --dport 139 -j ACCEPT
root@pi:~$ iptables -A INPUT -p tcp -i eth0 --dport 445 -j ACCEPT
```

Test the whole configuration. Once perfectly tested you can save this configuration in order to use it at each reboot. More details at https://debian-administration.org/article/445/Getting_IPTables_to_survive_a_reboot.

Save the current configuration:
```bash
root@pi:~$ iptables-save > /etc/firewall.conf
root@pi:~$ chmod 400 /etc/firewall.conf
```

Following lines might be removed from the configuration file firewall.conf:
```bash
:fail2ban-ssh - [0:0]
-A fail2ban-ssh -j RETURN
```

Create and edit the file /etc/network/if-up.d/iptables
```bash
#!/bin/sh
iptables-restore < /etc/firewall.conf
```

Make it executable:
```bash
root@pi:~$ chmod +x /etc/network/if-up.d/iptables
```

Reboot and the that the rules are still here by running:
```bash
root@pi:~$ iptables -L -v
```

And why doing the same on ip6tables?
Maybe you should think dropping undesirable ipv6 traffic.

## USB hard-drive on PI as backup

If you do not have RAID option on the distant machine and want to make sure that your data will not be lost forever if you lose your distant's hard-drive, I suggest you to do a backup on an USB drive connected to your PI.

The configuration is quite easy.

- Plug the USB drive to the PI
- List available partitions in it (ideally I would suggest to start with a cleaned partition in ext4 format)

```bash
root@pi:~$ # List the available drives
root@pi:~$ fdisk -l
root@pi:~$ # Specific to yours (replace /dev/sd[a-z] by your drive)
root@pi:~$ fdisk /dev/sd[a-z]
```

- (optional) Format the drive

```bash
root@pi:~$ fdisk /dev/sd[a-z]
root@pi:~$ mkfs.ext4 /dev/sd[a-z]
```

- Find disk the UUID of your disk

```bash
root@pi:~$ ls -alh /dev/disk/by-uuid/
```

- Auto-mount drive at start-up by adding a line in /etc/fstab (replace xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx by your uuid)

```bash
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /backup      ext4    defaults,errors=remount-ro 0       1
```

- Reload fstab

```bash
root@pi:~$ mount -a
```

- Copy the script [rsync-shared.sh](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/pi-example/rsync-shared.sh) into ~root/rsync-shared.sh
- Add a cron task to launch it automatically

```bash
root@pi:~$ crontab -e
```

And add a line like this one (rsync every 6 hours):

```bash
0 */6 * * * ~root/rsync-remote.sh
```

## Syncing your phone's data automatically

First of all download the app [Termux](https://play.google.com/store/apps/details?id=com.termux&hl=fr) on your Android mobile phone.
Then run commands ```àpt-get install rsync``` and ```àpt-get install ssh``` from termux.

The following configuration will make your phone able to sync its data towards the remote storage. It requires that both the phone and the Raspberry PI (or clear directory) connects to the VPN. The PI must provide a ssh access to the phone.

- Adapt iptables rules to give ssh access to the PI from machines running on the VPN. Ideally it would be great to narrow the range of machines able to access the ssh of the PI by adding a white list of MAC addresses for machines other than 10.8.0.1. Unfortunately it seems that the MAC of the phone is neither the wlan0 nor the telecom MAC when connected inside the VPN.

```bash
root@pi:~$ # No MAC filtering
root@pi:~$ iptables -A INPUT -p tcp -i tun0 -s 10.8.0.0/24 --dport ssh -j ACCEPT
root@pi:~$ # MAC filtering but does not seem to works when running inside the VPN
root@pi:~$ iptables -A INPUT -p tcp -i tun0 -s 10.8.0.0/24 -m mac --mac-source 00:11:22:33:44:55 --dport ssh -j ACCEPT
```

You may want to update /etc/firewall.conf after this change in order to make it available at next start. Please refer to previous parts to have more details on how you can do that.

- Allow <sambausername> to connect through VPN access

Edit /etc/ssh/sshd_config by modifying or adding:
```bash
AllowUsers pi sambausername

Match User sambausername
    AllowTCPForwarding no
    X11Forwarding no
    PasswordAuthentication no
```

And restart ssh service: ```service ssh restart```

- Generate ssh public key on your phone

````bash
termux@phone:~$ ssh-keygen -b 4096 -t rsa
termux@phone:~$ # Send .ssh/id_rsa.pub to the PI
```

````bash
sambausername@pi:~$ cat id_rsa_phone.pub >> ~sambausername/.ssh/authorized_keys
```

- Create a script on your phone like this one:

```bash
# Assumption: your PI has a fixed IP in the VPN (can be set easily using OpenVPN)
# IP would be 10.8.0.2 in the example
# Do remove --remove-source-files if you want to keep the files on your phone
backupdir=$(date +%d%m%Y-%H%M%S)
dest="/boxes/box/.backup"

ifconfig | grep tun0 && rsync -e ssh -zz -v -rtgoD --remove-source-files --backup-dir="${dest}/sdcard-${backupdir}" --exclude '.*' --exclude '*thumbnail*' /sdcard/DCIM sambausername@10.8.0.2:${dest}/sdcard/
ifconfig | grep tun0 && rsync -e ssh -zz -v -rtgoD --remove-source-files --backup-dir="${dest}/sdcard-${backupdir}" --exclude '.*' --exclude '*thumbnail*' /sdcard/Snapchat sambausername@10.8.0.2:${dest}/sdcard/
ifconfig | grep tun0 && rsync -e ssh -zz -v -rtgoD --remove-source-files --backup-dir="${dest}/sdcard1-${backupdir}" --exclude '.*' --exclude '*thumbnail*' /sdcard1/DCIM sambausername@10.8.0.2:${dest}/sdcard1/
ifconfig | grep tun0 && rsync -e ssh -zz -v -rtgoD --remove-source-files --backup-dir="${dest}/sdcard1-${backupdir}" --exclude '.*' --exclude '*thumbnail*' /sdcard1/Pictures sambausername@10.8.0.2:${dest}/sdcard1/
```

Please note that if this script is interrupted during its execution (for eg.: network down), it might leave backup directories on the destination. You can clean these empty backupd by running the commands:

```bash
root@pi:~$ cd /boxes/box/.backup/
root@pi:~$ find . -type d -empty -exec rmdir {} \;
```

- Launch it automatically... to be done...

## Access from Google Drive and other cloud solutions

It might be interesting to have a look to `rclone`. Having access to a limited subset of the storage from classic cloud services can be very useful. Data of those directories will be accessible within the inetrnal network as part of the drive and outside the network as basic cloud solutions.
