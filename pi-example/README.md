# Example of Raspberry PI configuration

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

OpenVPN installation is described at:
https://github.com/dubzzz/gnu-linux-tips/blob/master/openvpn/README.md
