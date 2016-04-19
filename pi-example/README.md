# Example of Raspberry PI configuration

## Bye-bye to your internet provider DNS

Edit /etc/network/interfaces by adding the DNS of your choice:
```bash
iface eth0 inet manual
    dns-nameservers 208.67.222.222 208.67.222.220
```

And restart the network interface (here eth0):
```bash
sudo ifdown eth0 && sudo ifup eth0
```

The file /etc/resolv.conf should contain your DNS servers.

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
root@server:~$ echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
root@server:~$ echo "yes" > /etc/pure-ftpd/conf/NoAnonymous
root@server:~$ echo "yes" > /etc/pure-ftpd/conf/NoChmod
root@server:~$ echo "113 002" > /etc/pure-ftpd/conf/Umask #file=664/folder=775 for consitency with samba
```

Don't forget to restart pure-ftpd service after any modifications of its configuration using:
```bash
root@server:~$ service pure-ftpd restart
```

#### Restrict FTP to OpenVPN users

There is no need to expose FTP to users outside of the VPN. Users in local network will have a network drive shared using Samba, users outside of the network should not be granted any accesses except when connecting in the provided VPN.

Moreover, FTP is too usesafe to be exposed to external clients.
