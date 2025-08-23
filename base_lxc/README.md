# Tofu configuration to build a base image

The Linux Container images [https://images.linuxcontainers.org/](https://images.linuxcontainers.org/)
rely on Cloud Init to be initialised and use systemd-networkd as the network settings manager.

Neither of these work with Pxvirt / Proxmox as Pxvirt / Proxmox can't configure LXCs with cloud init and it uses ifupdown2 to control the networking,

So, these images need to be adjusted to work with PXVIRT / Proxmox.

That is what this [Tofu](https://opentofu.org/) build does:

1. Switches networking to use ifupdown2.
2. Disables IPV6 (because that caused me weird errors).
3. Installed and enables SSH (because that allows further configuration).
