# Tofu (open source port of Terraform) configuration to build a various Pxvirt / Proxmox lxc images

The container images provided by [Pxvirt](https://github.com/jiangcuo/pxvirt/tree/pxvirt) at [https://download.lierfang.com/pxcloud/pxvirt/lxcs/](https://download.lierfang.com/pxcloud/pxvirt/lxcs/) are not that recent (as of 2025/08/23, they were from 2023). 

The container images provided through the ARM Pimox scripts at [https://pimox-scripts.vercel.app/scripts](https://pimox-scripts.vercel.app/scripts) e.g. for Debian [https://api.github.com/repos/asylumexp/debian-ifupdown2-lxc/releases/latest](https://api.github.com/repos/asylumexp/debian-ifupdown2-lxc/releases/latest) are also not that recent (as of 2025/08/23, they were from 2024/06/07).

[Turnkey Linux](https://www.turnkeylinux.org/) provides images that are more up-to-date, but even they seem to have a release cadence of over a year.

From a security perspective, this is less-than-ideal (vulnerabilities could creep in and not be rectified).

So it would be ideal to have relatively recent images.

There are potentially recent images available from the distributions themselves, e.g. the Debian Official Cloud Images at [https://cloud.debian.org/images/cloud/](https://cloud.debian.org/images/cloud/). But the configurations and availability of these could differ between vendors, so they might not provide a stable base to install further software on.

However, Linux Containers provides a set of recent images at
[https://images.linuxcontainers.org/](https://images.linuxcontainers.org/),
but these images rely on Cloud Init to be initialised and Pxvirt / Proxmox (versions 8 and 9) don't appear to be able to do Cloud Init - see: [https://forum.proxmox.com/threads/lxc-containers-cloud-init-and-hook-scripts.142115/](https://forum.proxmox.com/threads/lxc-containers-cloud-init-and-hook-scripts.142115/).

The container images from Linux Containers (at least the Debian ones) also use systemd-networkd as the network settings manager, but Pxvirt / Proxmox uses ifupdown2, so Pxvirt / Proxmox cannot set the network up - see [https://forum.proxmox.com/threads/debian-12-lxc-image-problem.129500/](https://forum.proxmox.com/threads/debian-12-lxc-image-problem.129500/).


So, these images need to be adjusted to work with PXVIRT / Proxmox, so that the networking uses ifupdown2, IPV6 is disabled (because that gives wierd errors) and sshd is installed so that it can be used as a standard communication mechanism to script further configration / image creation with.

Once that image is in place, a standard [Tofu](https://opentofu.org/) (Open-Source Terraform) LXC image can then be built and used to enable the containers to be built and controlled with Infrastructure as Code.
