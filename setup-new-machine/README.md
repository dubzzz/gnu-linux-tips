# Setup a new machine

You are given a new machine with root access only -- let say a fresh Debian setup.
This tutorial should give you hints to setup your machine step by step.

## SSH configuration

The aim of this step is to reduce the access to SSH to only one user different from root.
Why not root? Because it is the default user on all GNU/Linux setups.
So we will first create another user and grant him root rights.
Then SSH access will be allowed only for this user.

### Start with an updated system

```bash
root@server:~$ apt-get update && apt-get upgrade
```

### Install minimum required packages

```bash
root@server:~$ apt-get install screen vim fail2ban git sudo htop iftop
```

### Add an user and configure its space

```bash
root@server:~$ # Create a new user
root@server:~$ adduser <username>
root@server:~$ # Add him to sudoers
root@server:~$ usermod -a -G sudo <username>
root@server:~$ # Switch to this user to fullfill its configuration
root@server:~$ su <username>
<username>@server:~root$ cd ~<username>
<username>@server:~$ # Screen, Git and Bash configurations
<username>@server:~$ wget --no-check-certificate https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/misc/.bashrc.colors
<username>@server:~$ wget --no-check-certificate https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/misc/.screenrc
<username>@server:~$ wget --no-check-certificate https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
<username>@server:~$ mv git-prompt.sh .git-prompt.sh
<username>@server:~$ vim .bashrc
```

Append those lines to the existing ```.bashrc``` file:

```bash
# Custom PS1 for Git
source ~/.bashrc.colors
source ~/.git-prompt.sh
export PS1=$Yellow'\u'$Color_Off'@'$Cyan'\h'$Color_Off':'$Green'\w'$Color_Off'$(git branch &>/dev/null;\
if [ $? -eq 0 ]; then \
  echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
  if [ "$?" -eq "0" ]; then \
    # @4 - Clean repository - nothing to commit
    echo "'$Green'"$(__git_ps1 " (%s)"); \
  else \
    # @5 - Changes to working tree
    echo "'$IRed'"$(__git_ps1 " (%s)"); \
  fi) > '$Color_Off'"; \
else \
  # @2 - Prompt when not in GIT repo
  echo "\$ "; \
fi)'

# Only starts a screen if it is not already a screen
if [[ -z $STY ]]
then
        screen -x main select 1 || screen -R -S main;
fi
```

```bash
<username>@server:~$ # In case screen does not work you can try by running
<username>@server:~$ script /dev/null
```

### Grant user SSH access

```bash
root@server:~$ vim /etc/ssh/sshd_config
```

Here are the changes you should apply to your configuration file:

```bash
PermitRootLogin no
AllowUsers <username>
```

```bash
root@server:~$ service sshd reload
```

Before killing any running SSH session try to log again using <username>.

## Nothing in, nothing out by default

> `iptables` is being replaced by `nftables` starting with Debian Buster

Official guide for nftables in Debian is available at https://wiki.debian.org/nftables and a migration guide at https://wiki.nftables.org/wiki-nftables/index.php/Moving_from_iptables_to_nftables.

Let's adopt a pretty defensive `nftables` policy:

> Except explicitely opened, a port will be closed for in and out traffic.

### Configuration

ArchWiki comes with a pretty great documentation on how nftables should be configured: https://wiki.archlinux.org/index.php/Nftables.

```bash
# Enable a basic firewall
aptitude install nftables
systemctl enable nftables.service
# List existing rules
nft list ruleset
```

Then create a `firewall.sh` script containing:
```bash
# Adapted from https://wiki.archlinux.org/index.php/Nftables
# Flush the current ruleset
nft flush ruleset
# Add a table
nft add table inet my_table
# Add the input, forward, and output base chains. The policy for input and forward will be to drop. The policy for output will be to accept.
nft add chain inet my_table my_input '{ type filter hook input priority 0 ; policy drop ; }'
nft add chain inet my_table my_forward '{ type filter hook forward priority 0 ; policy drop ; }'
nft add chain inet my_table my_output '{ type filter hook output priority 0 ; policy accept ; }'
# Add two regular chains that will be associated with tcp and udp
nft add chain inet my_table my_tcp_chain
nft add chain inet my_table my_udp_chain
# Related and established traffic will be accepted
nft add rule inet my_table my_input ct state related,established accept
# All loopback interface traffic will be accepted
nft add rule inet my_table my_input iif lo accept
# Drop any invalid traffic
nft add rule inet my_table my_input ct state invalid drop
# Accept ICMP and IGMP
nft add rule inet my_table my_input meta l4proto ipv6-icmp icmpv6 type '{ destination-unreachable, packet-too-big, time-exceeded, parameter-problem, mld-listener-query, mld-listener-report, mld-listener-reduction, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, ind-neighbor-solicit, ind-neighbor-advert, mld2-listener-report }' accept
nft add rule inet my_table my_input meta l4proto icmp icmp type '{ destination-unreachable, router-solicitation, router-advertisement, time-exceeded, parameter-problem }' accept
nft add rule inet my_table my_input ip protocol igmp accept
# Rate limit on ping (without those rules, ping will be rejected)
nft add rule inet my_table my_input meta l4proto ipv6-icmp icmpv6 type echo-request counter limit rate 10/second accept
nft add rule inet my_table my_input meta l4proto icmp icmp type echo-request counter limit rate 10/second accept
# New udp (resp. tcp) traffic will jump to the UDP chain (resp. TCP chain)
nft add rule inet my_table my_input meta l4proto udp ct state new jump my_udp_chain
nft add rule inet my_table my_input 'meta l4proto tcp tcp flags & (fin|syn|rst|ack) == syn ct state new jump my_tcp_chain'
# Reject all traffic that was not processed by other rules
nft add rule inet my_table my_input meta l4proto udp reject
nft add rule inet my_table my_input meta l4proto tcp reject with tcp reset
nft add rule inet my_table my_input counter reject with icmpx type port-unreachable
# To accept SSH traffic on port 22 for interface called
nft add rule inet my_table my_tcp_chain tcp dport 22 accept
 # To accept VPN traffic
nft add rule inet my_table my_udp_chain udp dport 1194 accept
nft add rule inet my_table my_forward iifname tun0 oifname eno0 accept
nft add table ip nat
nft add chain ip nat prerouting '{ type nat hook prerouting priority 0; }'
nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; }'
nft add rule nat postrouting iifname tun0 oifname eno0 ip saddr 10.8.0.0/24 masquerade
```

Add execution right to it and execute it as root. Try to ping the machine, try to connect to it via ssh. If everything works fine, you are ready to save this configuration in order to apply it at next boot.

Remove `firewall.sh`. Save the configuration into `/etc/nftables/main.conf`:

```bash
mkdir /etc/nftables
cd /etc/nftables
nft list ruleset > main.conf
# everything that is ousite of my_table
```

Edit `/etc/nftables.conf` to use this configuration on next boot:

```txt
#!/usr/sbin/nft -f

flush ruleset
include "/etc/nftables/main.conf"
```

Create or edit `/etc/nftables/reload_main.conf` - _used to reload only the main table without the others like fail2ban_:

```txt
#!/usr/sbin/nft -f

delete table inet main
include "/etc/nftables/main.conf"
```

Make it executable using: `chmod 744 /etc/nftables/reload_main.conf`.

**Note:**
- `iptables-translate` may help you to transalte existing rules from `iptables` to `nft` command lines
- `inet` can be used to create rules for both `ip` and `ip6`

### Investigate network issues

```bash
root@server:~$ # List network interfaces (equivalent commands)
root@server:~$ ip link show
root@server:~$ netstat -i
root@server:~$ ifconfig -a
root@server:~$ # See routing tables
root@server:~$ ip r
root@server:~$ # See ARP cache
root@server:~$ arp
```

### Check ports

```bash
root@server:~$ # Show the port and listening socket associated with the service and lists both UDP and TCP protocols
root@server:~$ netstat -plunt
root@server:~$ # Scan for every TCP and UDP open port (from another server)
root@server:~$ nmap -n -PN -sT -sU -p- <remote_host>
```

## Development tools

```bash
root@server:~$ apt-get install git g++ clang vim cmake make libgtest-dev python-dev
root@server:~$ cd /usr/src/gtest
root@server:/usr/src/gtest$ cmake .
root@server:/usr/src/gtest$ make
root@server:/usr/src/gtest$ mv libgtest* /usr/lib/
```
