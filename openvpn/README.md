# OpenVPN

## OpenVPN server configuration

Root certificate
```bash
root@server:~$ apt-get install openvpn
root@server:~$ cp /usr/share/doc/openvpn/examples/easy-rsa ~/openvpn/ -R
root@server:~$ cd ~/openvpn/2.0/
root@server:~$ vim vars
root@server:~$ . ./vars
root@server:~$ ./clean-all
root@server:~$ ./build-ca
```

Certicate and server' key
```bash
root@server:~$ ./build-key-server server
```

Certicate and clients' keys
```bash
root@server:~$ ./build-key client1
```

Diffie-Hellman
```bash
root@server:~$ ./build-dh
```

Server configuration
```bash
root@server:~$ cp keys/dh*.pem keys/ca.crt keys/server.crt keys/server.key /etc/openvpn/
root@server:~$ cd /usr/share/doc/openvpn/examples/sample-config-files
root@server:~$ gunzip server.conf.gz
root@server:~$ cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/
```

Edit /etc/openvpn/server.conf, you can give it following settings for instance:
```bash
push "redirect-gateway" ;or push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222" ;OpenDNS
push "dhcp-option DNS 208.67.220.220"
```

Enable ip forward: these commands have to be run at each restart
```bash
root@server:~$ iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
root@server:~$ echo "1" > /proc/sys/net/ipv4/ip_forward
root@server:~$ service openvpn restart
```

NOTE: you can change the password of a certificate by running
```bash
root@server:~$ openssl rsa -des3 -in client1.key -out client1.bis.key
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
