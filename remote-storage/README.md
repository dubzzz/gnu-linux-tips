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

Edit /etc/ssh/sshd_config
```bash
## /etc/ssh/sshd_config
Match User scpuser
    ChrootDirectory /home/jails
    ForceCommand internal-sftp
    AllowTCPForwarding no
    X11Forwarding no
    PasswordAuthentication no
```

If you are using ```AllowUsers``` tag in ```/etc/ssh/sshd_config``` file make sure to append the user ```scpuser``` to the list as follow:
```
AllowUsers user1 user2 scpuser
```

Creating the user
```bash
root@remote:~$ service ssh restart
root@remote:~$ mkdir -p /home/jails/home
root@remote:~$ adduser --disabled-password --home /home/jails/home/scpuser --shell /bin/false scpuser
```

## Mount the drive manually

Generate the public key on the _internal server_ and add it to user scpuser of the _remote server_.
If you are generating the key for a non-root user, you should configure it with a password for higher safety.
```bash
# user1@internal must be replaced by root@internal when mounting from script (see below)
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
root@internal:~$ chown user1:user1 /boxes/*  # Not required when mounting from script (see below)
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

Required packages
```bash
root@internal:~$ apt-get install samba
```

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

Normally you should be able to login. If it fails you might have a look into samba's logs (increase the level to 4).
If you see something like `LanMan nor NT password supplied for user`, you might try what suggested in https://superuser.com/questions/1408271/win-10-connecting-to-samba-on-raspbian-gives-wrong-password

The solution is to update the regedit key called LmCompatibilityLevel to 3 (or more) in HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa.

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
*/5 * * * * /etc/init.d/remote-storage status || /etc/init.d/remote-storage force-start || /etc/init.d/remote-storage restart || /etc/init.d/remote-storage force-restart
```

## Sources
- http://lea-linux.org/documentations/SFTP_%26_RSSH_:_Cr%C3%A9er_un_serveur_de_fichiers_s%C3%A9curis%C3%A9
- http://www.herethere.net/~samson/rssh_chroot.html
- https://doc.ubuntu-fr.org/sshfs [with fstab no encfs]
- http://www.jinnko.org/2010/11/using-autofs-to-mount-encfs-over-cifs.html [with fstab]
- https://askubuntu.com/questions/134425/how-can-i-chroot-sftp-only-ssh-users-into-their-homes
- https://wiki.archlinux.org/index.php/SFTP_chroot#Scponly
- https://unix.stackexchange.com/questions/9853/restricting-an-ssh-scp-sftp-user-to-a-directory
- https://github.com/scponly/scponly/wiki/Install
