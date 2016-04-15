# Distant Storage

The aim of this section is to describe a way to deploy an encrypted distant storage. The resulting setup is:
- distant server: owns encrypted data it cannot read
- internal server: decrypts/encrypts data stored on distant on the fly using user scpuser
- other machine: accesses plain data without the need to encrypt anything

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
root@distant:~$ wget http://jeannedarc001.free.fr/mkdep
root@distant:~$ chmod +x mkdep
root@distant:~$ # Binaries and libs
root@distant:~$ ./mkdep /usr/bin/rssh .
root@distant:~$ ./mkdep /usr/bin/sftp .
root@distant:~$ ./mkdep /usr/lib/rssh/rssh_chroot_helper .
root@distant:~$ ./mkdep /usr/lib/sftp-server .
root@distant:~$ ./mkdep /usr/bin/scp .
root@distant:~$ # Config files
root@distant:~$ mkdir etc
root@distant:~$ cp /etc/rssh.conf etc/
root@distant:~$ grep '^scpuser:' /home/jails/etc/passwd || grep '^scpuser:' /etc/passwd >> /home/jails/etc/passwd
root@distant:~$ cp -p /etc/group /home/jails/etc/group
root@distant:~$ # Device files
root@distant:~$ mkdir dev
root@distant:~$ mknod dev/zero c 1 5
root@distant:~$ mknod dev/null c 1 3
root@distant:~$ chmod 666 dev/*
```

## Sources
- http://lea-linux.org/documentations/SFTP_%26_RSSH_:_Cr%C3%A9er_un_serveur_de_fichiers_s%C3%A9curis%C3%A9
- http://www.herethere.net/~samson/rssh_chroot.html
