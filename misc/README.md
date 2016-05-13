# Misc

## Basic configuration files

Download and install ```screen```.
Copy the files [.bashrc](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/misc/.bashrc), [.bashrc.colors](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/misc/.bashrc.colors) and [.screenrc](https://raw.githubusercontent.com/dubzzz/gnu-linux-tips/master/misc/.screenrc) into your home directory.

Download git-prompt script:

```bash
root@server:~$ wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh ~/.git-prompt.sh
root@server:~$ chmod u+x ~/.git-prompt.sh
```

## Who is listening to which port?

```bash
root@server:~$ netstat -tulpn
```
