# FTP - File Transfer Protocol

## Basic FTP

The following section describes how to setup a basic FTP server on your machine.
FTP is sending data in clear-text without any protections.
If you want to protect the data you must choose FTPS (ssl-based) or SFTP (ssh-based).
These two protocols will not be discussed in this section.

```bash
root@server:~$ apt-get install pure-ftpd
```

### Create a virtual user and add it to available ones

```bash
root@server:~$ pure-pw useradd sambausername -u sambausername -g sambausername -d /boxes/box #-u <username> -g <group> -d <home>
root@server:~$ pure-pw mkdb
root@server:~$ ln -s /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/50pure
```

### Customize configuration

Customization of pure-ftpd is handled by files stored in /etc/pure-ftpd/conf/.
A list of available settings can be found at https://doc.ubuntu-fr.org/pure-ftp.

For instance:
```bash
root@server:~$ echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
root@server:~$ echo "40000 40500" > /etc/pure-ftpd/conf/PassivePortRange
root@server:~$ echo "133 022" > /etc/pure-ftpd/conf/Umask #file=644/folder=755
```

### Apply changes

```bash
root@server:~$ service pure-ftpd restart
```

Sources:
- [Ubuntu FR](https://doc.ubuntu-fr.org/pure-ftp)
