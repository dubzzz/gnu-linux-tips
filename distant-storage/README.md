# Distant Storage

The aim of this section is to describe a way to deploy an encrypted distant storage. The resulting setup is:
- distant server: owns encrypted data it cannot read
- internal server: decrypts/encrypts data stored on distant on the fly using user scpuser
- other machine: accesses plain data without the need to encrypt anything

![Final architecture](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/distant-storage/distant-storage.png "Final architecture")

## Only scp and sftp on distant machine

Install rssh
```bash
root@distant:~$ apt-get install rssh
root@distant:~$ grep "$(which rssh)" /etc/shells || which rssh >> /etc/shells
root@distant:~$ mv /etc/rssh.conf /etc/rssh.conf.old
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
root@distant:~$ service ssh restart
root@distant:~$ mkdir -p /home/jails/home
root@distant:~$ adduser --disabled-password --home /home/jails/home/scpuser --shell "$(which rssh)" scpuser
```

## No root access on distant machine

__The following configuration does not work yet but can be the base of a working one.__

Uncomment chroot options
```bash
root@distant:~$ vim /etc/rssh.conf
root@distant:~$ vim /etc/ssh/sshd_config
root@distant:~$ service ssh restart
```

Create jails (a kind of second root)
```bash
root@distant:~$ cd /home/jails
root@distant:/home/jails$ wget https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/distant-storage/mkdep #http://jeannedarc001.free.fr/mkdep
root@distant:/home/jails$ chmod +x mkdep
root@distant:/home/jails$ # Binaries and libs
root@distant:/home/jails$ ./mkdep /usr/bin/rssh .
root@distant:/home/jails$ ./mkdep /usr/bin/sftp .
root@distant:/home/jails$ ./mkdep /usr/lib/rssh/rssh_chroot_helper .
root@distant:/home/jails$ ./mkdep /usr/lib/sftp-server .
root@distant:/home/jails$ ./mkdep /usr/bin/scp .
root@distant:/home/jails$ # Config files
root@distant:/home/jails$ mkdir etc
root@distant:/home/jails$ cp /etc/rssh.conf etc/
root@distant:/home/jails$ grep '^scpuser:' /home/jails/etc/passwd || grep '^scpuser:' /etc/passwd >> /home/jails/etc/passwd
root@distant:/home/jails$ cp -p /etc/group /home/jails/etc/group
root@distant:/home/jails$ # Device files
root@distant:/home/jails$ mkdir dev
root@distant:/home/jails$ mknod dev/zero c 1 5
root@distant:/home/jails$ mknod dev/null c 1 3
root@distant:/home/jails$ chmod 666 dev/*
```

## Mount the drive manually

Generate the public key on the _internal server_ and add it to user scpuser of the _distant server_.
If you are generating the key for a non-root user, you should configure it with a password for higher safety.
```bash
user1@internal:~$ ssh-keygen -b 4096 -t rsa
user1@internal:~$ scp ~/.ssh/id_rsa.pub user1@distant:id_rsa_internal.pub
```

Add the public key of user1@internal to the authorized keys of scpuser@distant.
```bash
root@distant:~$ cat ~user1/id_rsa_internal.pub >> ~scpuser/.ssh/authorized_keys
root@distant:~$ rm ~user1/id_rsa_internal.pub
root@distant:~$ mkdir ~scpuser/box #directory hosting the encrypted data
```

Configure the file structure to host the distant drive
```bash
root@internal:~$ mkdir /boxes
root@internal:~$ chmod 755 /boxes
root@internal:~$ mkdir /boxes/.box_enc
root@internal:~$ mkdir /boxes/box
root@internal:~$ chown user1:user1 /boxes/*
root@internal:~$ chmod 770 /boxes/*
```

Mount distant drive
```bash
user1@internal:~$ sshfs scpuser@distant:box /boxes/.box_enc -o uid=$(id -u) -o gid=$(id -g)
user1@internal:~$ encfs /boxes/.box_enc /boxes/box
```

Unmount distant drive
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
[Example](/)

## Sources
- http://lea-linux.org/documentations/SFTP_%26_RSSH_:_Cr%C3%A9er_un_serveur_de_fichiers_s%C3%A9curis%C3%A9
- http://www.herethere.net/~samson/rssh_chroot.html
