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
root@server:~$ apt-get install screen vim fail2ban git sudo
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

## Development tools

```bash
root@server:~$ apt-get install git g++ clang vim cmake make libgtest-dev
```
