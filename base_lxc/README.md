
# Tofu configuration to build a base image

The container images provided are really out-of-date.

So it would be ideal to have relatively recent images.

Linux Containers provides a set of images at
[https://images.linuxcontainers.org/](https://images.linuxcontainers.org/),
but these images rely on Cloud Init to be initialised.

These images also don't use ifupdown2 to control the networking,
but Tofu requires ifupdown2.

So, these images need to be adjusted to work with PXVIRT / Proxmox.

That is what this build does:

1. Switches networking to use ifupdown2.
2. Disables IPV6 (because that caused me weird errors).
3. Installed and enabled SSH (because that allows further configuration).
