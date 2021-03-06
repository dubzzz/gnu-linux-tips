# OpenVPN

## Table of contents

- [OpenVPN server configuration](#openvpn-server-configuration)
- [Who needs what?](#who-needs-what)
- [OpenVPN for Android](#openvpn-for-android)
- [OpenVPN for GNU/Linux client](#openvpn-for-gnulinux-client)
- [OpenVPN for Windows](#openvpn-for-windows)
- [Debug](#debug)

## OpenVPN server configuration

### Create certificates

#### Debian (10.x)

```bash
## Debian (version 10.x)
root@server:~$ apt-get install openvpn easy-rsa
root@server:~$ make-cadir openvpn
root@server:~$ cd ~/openvpn/
root@server:~$ ./easyrsa init-pki
root@server:~$ ./easy-rsa build-ca
root@server:~$ ./easyrsa build-server-full server
root@server:~$ ./easyrsa build-client-full client-a
root@server:~$ ./easyrsa build-client-full client-b
root@server:~$ ./easyrsa gen-dh
```

#### Debian (7-8.x)

Root certificate
```bash
## Debian Wheezy (version 7.x)
root@server:~$ apt-get install openvpn
root@server:~$ cp /usr/share/doc/openvpn/examples/easy-rsa ~/openvpn/ -R
root@server:~$ cd ~/openvpn/2.0/

## Raspbian Jessie (version 8.x)
root@server:~$ apt-get install openvpn easy-rsa
root@server:~$ make-cadir openvpn
root@server:~$ cd ~/openvpn/
```

Then,
```bash
root@server:~/<openvpn>/$ vim vars #increase key size to 2048, KEY_SIZE=2048 => /etc/openvpn/server.conf "dh dh2048.pem"
root@server:~/<openvpn>/$ . ./vars
root@server:~/<openvpn>/$ ./clean-all
root@server:~/<openvpn>/$ ./build-ca
```

Certicate and server' key
```bash
root@server:~/<openvpn>/$ ./build-key-server server
```

Certicate and clients' keys
```bash
root@server:~/<openvpn>/$ ./build-key client1
```

Diffie-Hellman
```bash
root@server:~/<openvpn>/$ ./build-dh
```

TLS
```bash
root@server:~/<openvpn>/$ openvpn --genkey --secret ta.key
```

### Use certificates

Server configuration
```bash
# For Debian 10.x
root@server:~/<openvpn>/$ cp pki/ca.crt pki/dh.pem pki/issued/server.crt pki/private/server.key /etc/openvpn/
# Before Debian 10.x
root@server:~/<openvpn>/$ cp keys/dh*.pem keys/ca.crt keys/server.crt keys/server.key /etc/openvpn/

# For any version
root@server:~/<openvpn>/$ cd /usr/share/doc/openvpn/examples/sample-config-files
root@server:/usr/share/doc/openvpn/examples/sample-config-files$ gunzip server.conf.gz
root@server:/usr/share/doc/openvpn/examples/sample-config-files$ cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/

# For Debian 10.x
root@server:/etc/openvpn/$ openvpn --genkey --secret /etc/openvpn/server/ta.key
```

Edit /etc/openvpn/server.conf, you can give it following settings for instance:
```bash
push "redirect-gateway" ;or push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222" ;OpenDNS
push "dhcp-option DNS 208.67.220.220"
```

Enable ip forward: these commands have to be run at each restart
```bash
# Debian 10.x
root@server:~$ vim /etc/sysctl.conf # Uncomment net.ipv4.ip_forward=1
root@server:~$ sysctl -p
# See https://palitechsociety.blogspot.com/2019/07/openvpn-server-on-debian-10.html

# uncomment 
# Debian <10.x
root@server:~$ /sbin/iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
root@server:~$ echo "1" > /proc/sys/net/ipv4/ip_forward
root@server:~$ service openvpn restart
```

In order to run it on each reboot of your machine you can create a script under ~root/openvpn-on-reboot.sh with rights 500 (for root) and create a new crontab task (```crontab -e```) having the following code:
```bash
@reboot ~/openvpn-on-reboot.sh
```

NOTE: you can change the password of a certificate by running
```bash
root@server:~/<openvpn>/$ openssl rsa -des3 -in client1.key -out client1.bis.key
```

NOTE: OpenVPN has a way to debug configuration files for both server and client
```bash
root@server:~$ cd /etc/openvpn && openvpn server.conf #server
root@client:~$ cd /etc/openvpn && openvpn client.conf #client
```

NOTE: If debuging of configuration files goes right but normal start fails, try to edit the file /etc/default/openvpn to specify the default configuration file that should be used. You might need to restart the computers to get it work
```bash
AUTOSTART="server" #AUTOSTART="client"
```

NOTE: Assign static ip to user <client-name>
```bash
root@server:~$ mkdir /etc/openvpn/ccd
root@server:~$ vim /etc/openvpn/server.conf
```
```bash
client-config-dir ccd
```
```bash
root@server:~$ vim /etc/openvpn/ccd/<client-name> # Assign <client-name> to IP 10.8.0.100
```
```bash
ifconfig-push 10.8.0.100 255.255.255.0
```

## Who needs what?

Both server and client:
- ca.crt

Server only:
- server.crt
- server.key
- dh1024.pem

Client only:
- client.crt
- client.key

## OpenVPN for Android

[Available on Play Store](https://play.google.com/store/apps/details?id=net.openvpn.openvpn)

Android version accepts `*.ovpn` file, they are structured as follow:
```txt
client
proto udp
remote new.dubien.me
port 1194
dev tun
nobind
cipher AES-256-CBC
comp-lzo yes
key-direction 1

<ca>
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
</ca>

<cert>
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
</key>

<tls-auth>
-----BEGIN OpenVPN Static key V1-----
...
-----END OpenVPN Static key V1-----
</tls-auth>
```

Android version requires a specific key that can be generated using:
```bash
root@server:~$ openssl pkcs12 -export -in client1.crt -inkey client1.key -certfile ca.crt -name client1 -out client1.p12
```

## OpenVPN for GNU/Linux client

```bash
root@client:~$ apt-get install openvpn
```

Retrieve certificates generated by the server
```bash
root@client:~$ cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn
root@client:~$ vim /etc/openvpn/client.conf
root@client:~$ scp server:openvpn/2.0/keys/ca.crt ~
root@client:~$ scp server:openvpn/2.0/keys/client1.crt ~
root@client:~$ scp server:openvpn/2.0/keys/client1.key ~
root@client:~$ mv ~/ca.crt ~/client1.crt ~/client1.key /etc/openvpn/
```

The configuration file `/etc/openvpn/client.conf` have to be updated to be able to connect to the remote server:
- Define `remote <ip-or-host> 1194`
- Edit the SSL/TLS configuration files to: `ca ca.crt`, `cert client1.crt` and `key client1.key`
- Make sure whether or not you are relying on `udp` (default) or `tcp`
- Make sure you need `tls-auth` (use `;` if not configured server-side)
- Make sure you need `comp-lzo` (use `;` if not configured server-side)
- Make sure you use the right `cipher`

Edit the file `/etc/default/openvpn` to specify the default configuration file that should be used.

```bash
AUTOSTART="client"
```

If you want to configure OpenVPN through a UI, you may try the following:

```bash
root@client:~$ apt-get install network-manager-openvpn
```

Configure network-manager-openvpn to use LZ0 compression (if set on server-side too)
- Réseaux > Connexions VPN > Configurer le VPN..
- Sélectionner le VPN à modifier
- Cliquer sur modifier
- VPN > Avancé.. > Utiliser la compression de données LZO

Prevent the machine from logging on the VPN automatically
```bash
root@client:~$ update-rc.d openvpn remove
```

Add it back (autostart)
```bash
root@client:~$ update-rc.d openvpn defaults
```

Note: if you want to use a signed certificate with a password, you can store this password on your file system. It must me owned by root:root with rights 400 or 500 (if it can be run).

# OpenVPN for Windows

[Available on OpenVPN official website](https://openvpn.net/index.php/open-source/downloads.html)

# Debug

In order to debug on server-side you can run the command:
```bash
root@server:~$ tcpdump -i eth0 udp port 1194
root@server:~$ tcpdump -i tun0
```

You can troubleshoot issues on client-side by running the following commands:
```bash
root@client:~$ traceroute 8.8.8.8
root@client:~$ ip route show
root@client:~$ ip route list
root@client:~$ netstat -nr
```

My local network is very unstable making disconnections from internet quite usual. Each time I disconnected from the internet my only way to ping back throughout the VPN was to stop and start again the VPN connection using:
```bash
root@client:~$ service openvpn stop
root@client:~$ service openvpn start
```

Another way to solve the issue was to re-add the missing route that disappeared during disconnection:
```bash
root@client:~$ # ip route add <server ip> dev <local network interface> src <gateway ip in local network>
root@client:~$ ip route add 37.187.109.86 dev eth0 src 192.168.0.1
```

Here are the outputs I got when running route commands:
```bash
root@client:~$ # When everything is OK
root@client:~$ ip route show

default via 255.255.255.0 dev tun0
default via 192.168.0.1 dev eth0  metric 206
10.8.0.1 via 255.255.255.0 dev tun0
37.187.109.86 via 192.168.0.1 dev eth0
192.168.0.0/24 dev eth0  proto kernel  scope link  src 192.168.0.9  metric 206
255.255.255.0 dev tun0  proto kernel  scope link  src 10.8.0.9

root@client:~$ # Just after a disconnect
root@client:~$ ip route show

default via 255.255.255.0 dev tun0
default via 192.168.0.1 dev eth0  metric 206
10.8.0.1 via 255.255.255.0 dev tun0
192.168.0.0/24 dev eth0  proto kernel  scope link  src 192.168.0.9  metric 206
255.255.255.0 dev tun0  proto kernel  scope link  src 10.8.0.9
```

Here are some error logs you might find in `/var/log/syslog` if OpenVPN fails to start correctly:

- `Authenticate/Decrypt packet error: cipher final failed` -> check the `cipher` option
- `Options error: --tls-auth fails with 'ta.key': No such file or directory` -> check the `tls-auth` option
