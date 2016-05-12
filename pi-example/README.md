# Example of Raspberry PI configuration

## Bye-bye to your internet provider DNS

Edit /etc/resolv.conf:
```bash
nameserver 208.67.222.222
nameserver 208.67.222.220
```

Then run the following command to block the modification of the file:
```bash
root@server:~$ chattr +i /etc/resolv.conf
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
root@server:~$ echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
root@server:~$ echo "yes" > /etc/pure-ftpd/conf/NoAnonymous
root@server:~$ echo "yes" > /etc/pure-ftpd/conf/NoChmod
root@server:~$ echo "40000 40500" > /etc/pure-ftpd/conf/PassivePortRange
root@server:~$ echo "113 002" > /etc/pure-ftpd/conf/Umask #file=664/folder=775 for consitency with samba
```

Don't forget to restart pure-ftpd service after any modifications of its configuration using:
```bash
root@server:~$ service pure-ftpd restart
```

#### Restrict FTP to OpenVPN users

There is no need to expose FTP to users outside of the VPN. Users in local network will have a network drive shared using Samba, users outside of the network should not be granted any accesses except when connecting in the provided VPN.

Moreover, FTP is too usesafe to be exposed to external clients.

## Firewall configuration

For higher security in both local and vpn networks I suggest to increase firewall protection on the PI itself.
Please run these commands carefully as they may block access to some of the running services.

```bash
root@server:~$ # Flush input rules, apply drop policy on inputs, do not kill exitsing connections and allow internal loop
root@server:~$ iptables -F INPUT ; iptables -P INPUT DROP ; iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT ; iptables -I INPUT -i lo -j ACCEPT
root@server:~$ # Apply accept policy on outputs and forward
root@server:~$ iptables -P OUTPUT DROP ; iptables -P FORWARD DROP
root@server:~$ # Allow ping from all interfaces (eth0, tun0...)
root@server:~$ iptables -A INPUT -p icmp -j ACCEPT
root@server:~$ # Limit SSH access to local network (on eth0 only) and VPN root server
root@server:~$ iptables -A INPUT -p tcp -i eth0 --dport ssh -j ACCEPT
root@server:~$ iptables -A INPUT -p tcp -i tun0 -s 10.8.0.1 --dport ssh -j ACCEPT
root@server:~$ # Limit FTP access to VPN users only
root@server:~$ iptables -A INPUT -p tcp -i tun0 -s 10.8.0.0/24 --dport ftp -j ACCEPT
root@server:~$ iptables -A INPUT -p tcp -i tun0 -s 10.8.0.0/24 --dport 40000:40500 -j ACCEPT
root@server:~$ # Limit Samba access to local network
root@server:~$ iptables -A INPUT -p tcp -i eth0 --dport 137 -j ACCEPT
root@server:~$ iptables -A INPUT -p udp -i eth0 --dport 138 -j ACCEPT
root@server:~$ iptables -A INPUT -p udp -i eth0 --dport 139 -j ACCEPT
root@server:~$ iptables -A INPUT -p tcp -i eth0 --dport 445 -j ACCEPT
```

Test the whole configuration. Once perfectly tested you can save this configuration in order to use it at each reboot. More details at https://debian-administration.org/article/445/Getting_IPTables_to_survive_a_reboot.

Save the current configuration:
```bash
root@server:~$ iptables-save > /etc/firewall.conf
root@server:~$ chmod 400 /etc/firewall.conf
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
root@server:~$ chmod +x /etc/network/if-up.d/iptables
```

Reboot and the that the rules are still here by running:
```bash
root@server:~$ iptables -L -v
```

And why doing the same on ip6tables?
Maybe you should think dropping undesirable ipv6 traffic.

## Why not using a local storage as backup?

Please refer to: [rsync-shared.sh](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/pi-example/rsync-shared.sh)
