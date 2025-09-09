# Tofu configuration to build an image containing PostgreSQL

The Linux Container images [https://images.linuxcontainers.org/](https://images.linuxcontainers.org/)
rely on Cloud Init to be initialised and use systemd-networkd as the network settings manager.

This takes an base image modified from a Linux Container image and adds PostgreSQL to it.

At present it adds the version of PostgreSQL available in the standard Debian Bookworm:
- PostgreSQL version 15

```console
$ tofu init
$ TF_VAR_root_password='' tofu plan --var-file="ip_addrs.tfvars"
$ TF_VAR_root_password='' tofu apply -var-file="ip_addrs.tfvars"
```
