# Remote Storage

The aim of this section is to describe a way to deploy an encrypted remote storage. The resulting setup is:
- remote server: owns encrypted data it cannot read
- internal server: decrypts/encrypts data stored on remote on the fly using user scpuser
- other machine: accesses plain data without the need to encrypt anything

![Final architecture](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/remote-storage/remote-storage.png "Final architecture")

## Table of Contents

- [Only scp and sftp on remote machine](#only-scp-and-sftp-on-remote-machine)
- [No root access on remote machine](#no-root-access-on-remote-machine)
- [Mount the drive manually](#mount-the-drive-manually)
- [Example of usage: samba](#example-of-usage-samba)
- [Mount the drive by script](#mount-the-drive-by-script)
- [Sources](#sources)

## Only scp and sftp on remote machine

Install rssh
```bash
root@remote:~$ apt-get install rssh
root@remote:~$ grep "$(which rssh)" /etc/shells || which rssh >> /etc/shells
root@remote:~$ mv /etc/rssh.conf /etc/rssh.conf.old
```

Edit /etc/rssh.conf
```bash
## /etc/rssh.conf
logfacility = LOG_USER
allowscp
allowsftp
umask = 022
#chrootpath = "/home/jails"
```

Edit /etc/ssh/sshd_config
```bash
## /etc/ssh/sshd_config
Match User scpuser
    #ChrootDirectory /home/jails
    AllowTCPForwarding no
    X11Forwarding no
    PasswordAuthentication no
```

Creating the user
```bash
root@remote:~$ service ssh restart
root@remote:~$ mkdir -p /home/jails/home
root@remote:~$ adduser --disabled-password --home /home/jails/home/scpuser --shell "$(which rssh)" scpuser
```

## No root access on remote machine

__The following configuration does not work yet but can be the base of a working one.__

Uncomment chroot options
```bash
root@remote:~$ vim /etc/rssh.conf
root@remote:~$ vim /etc/ssh/sshd_config
root@remote:~$ service ssh restart
```

Create jails (a kind of second root)
```bash
root@remote:~$ cd /home/jails
root@remote:/home/jails$ wget https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/remote-storage/mkdep #http://jeannedarc001.free.fr/mkdep
root@remote:/home/jails$ chmod +x mkdep
root@remote:/home/jails$ # Binaries and libs
root@remote:/home/jails$ ./mkdep /usr/bin/rssh .
root@remote:/home/jails$ ./mkdep /usr/bin/sftp .
root@remote:/home/jails$ ./mkdep /usr/lib/rssh/rssh_chroot_helper .
root@remote:/home/jails$ ./mkdep /usr/lib/sftp-server .
root@remote:/home/jails$ ./mkdep /usr/bin/scp .
root@remote:/home/jails$ # Config files
root@remote:/home/jails$ mkdir etc
root@remote:/home/jails$ cp /etc/rssh.conf etc/
root@remote:/home/jails$ grep '^scpuser:' /home/jails/etc/passwd || grep '^scpuser:' /etc/passwd >> /home/jails/etc/passwd
root@remote:/home/jails$ cp -p /etc/group /home/jails/etc/group
root@remote:/home/jails$ # Device files
root@remote:/home/jails$ mkdir dev
root@remote:/home/jails$ mknod dev/zero c 1 5
root@remote:/home/jails$ mknod dev/null c 1 3
root@remote:/home/jails$ chmod 666 dev/*
```

## Mount the drive manually

Generate the public key on the _internal server_ and add it to user scpuser of the _remote server_.
If you are generating the key for a non-root user, you should configure it with a password for higher safety.
```bash
user1@internal:~$ ssh-keygen -b 4096 -t rsa
user1@internal:~$ scp ~/.ssh/id_rsa.pub user1@remote:id_rsa_internal.pub
```

Add the public key of user1@internal to the authorized keys of scpuser@remote.
```bash
root@remote:~$ cat ~user1/id_rsa_internal.pub >> ~scpuser/.ssh/authorized_keys
root@remote:~$ rm ~user1/id_rsa_internal.pub
root@remote:~$ mkdir ~scpuser/box #directory hosting the encrypted data
```

Configure the file structure to host the remote drive
```bash
root@internal:~$ mkdir /boxes
root@internal:~$ chmod 755 /boxes
root@internal:~$ mkdir /boxes/.box_enc
root@internal:~$ mkdir /boxes/box
root@internal:~$ chown user1:user1 /boxes/*
root@internal:~$ chmod 770 /boxes/*
```

Required packages
```bash
root@internal:~$ apt-get install sshfs encfs
```

Mount remote drive
```bash
user1@internal:~$ sshfs scpuser@remote:box /boxes/.box_enc -o uid=$(id -u) -o gid=$(id -g)
user1@internal:~$ encfs /boxes/.box_enc /boxes/box
```

Unmount remote drive
```bash
user1@internal:~$ fusermount -u /boxes/box
user1@internal:~$ fusermount -u /boxes/.box_enc
```

## Example of usage: samba

Add Samba user
```bash
root@internal:~$ adduser --no-create-home --disabled-password --disabled-login sambausername
root@internal:~$ smbpasswd -a sambausername
```

Backup and configure Samba
```bash
root@internal:~$ cp /etc/samba/smb.conf /etc/samba/smb.conf.old
root@internal:~$ service smbd restart
```
[Example](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/remote-storage/smb.conf)

Useful commands
```bash
# Change password of the user toto
root@server:~$ smbpasswd -a toto
```

## Mount the drive by script

Create a public key for root user of internal and send it to remote machine in order to be able to log as scpuser (add it to authorized_keys of scpuser as done above).

Useful command for the scripts: find uid/gid of the user sambausername
```bash
cat /etc/passwd | grep sambausername #find uid/gid of the user sambausername
```

[Script: start/stop/restart shared](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/remote-storage/remote-script.sh)
```bash
# Mount remote drive and start samba
root@internal:~$ ./remote-script.sh start #does not ask you a password, use force-start to force the start when partially started (force-start, starts missing parts only -- start fails if something has already been started before)
# Unmount remote drive and stop samba
root@internal:~$ ./remote-script.sh stop #use force-stop to force (force might be dangerous as it force the unmount)
# Restart the remote drive
root@internal:~$ ./remote-script.sh restart #call stop followed by start, use force-restart to force
# Status of the remote storage
root@internal:~$ ./remote-script.sh status
```

## Auto-mount at startup

### Register the new service

Copy the scripts:
- [remote script](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/remote-storage/remote-script.sh)
into root's home. Adapt the script variables to your needs (username, password, server and eventually password file)

Copy the script [remote-storage.sh](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/remote-storage/remote-storage.sh) into /etc/init.d/remote-storage.

```bash
root@internal:~$ chmod u+x /etc/init.d/remote-storage
root@internal:~$ update-rc.d remote-storage defaults
```

### Register to network up/down

Copy [ifupd-remote-storage.sh](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/remote-storage/ifupd-remote-storage.sh) into /etc/network/if-up.d/remote-storage.

```bash
root@internal:~$ chmod +x /etc/network/if-up.d/remote-storage
```

### No password

If you don't want to enter the password each time you call the service, you can create a script like:
```bash
#!/bin/sh
echo "password"
```

And change its mode to 500 and its owner to root.

Then you have to add the option --extpass=/my/password/script to encfs command in start-shared script.

## Auto-mount if disconnected

Add the following query to your crontab (as root): `crontab -e`
```bash
# restart if down (or partially down)
*/5 * * * * /etc/init.d/remote-storage status || /etc/init.d/remote-storage force-start

# or even more powerfull
# force restart if down
*/5 * * * * /etc/init.d/remote-storage status || /etc/init.d/remote-storage force-start || /etc/init.d/remote-storage restart || remote-storage force-restart
```

## Sources
- http://lea-linux.org/documentations/SFTP_%26_RSSH_:_Cr%C3%A9er_un_serveur_de_fichiers_s%C3%A9curis%C3%A9
- http://www.herethere.net/~samson/rssh_chroot.html
- https://doc.ubuntu-fr.org/sshfs [with fstab no encfs]
- http://www.jinnko.org/2010/11/using-autofs-to-mount-encfs-over-cifs.html [with fstab]
