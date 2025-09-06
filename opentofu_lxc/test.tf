locals {
  target_name_test = "${var.target_name}-test"

  # Note, possibly the templatestring function would be more appropriate:
  # https://developer.hashicorp.com/terraform/language/functions/templatestring
}

resource "tls_private_key" "ssh" {
  depends_on       = [
    # terraform_data.shutdown_guest_and_backup
    proxmox_virtual_environment_file.ct_template
  ]
  algorithm = "ED25519"
}

resource "proxmox_lxc" "test_lxc" {
  depends_on       = [
    tls_private_key.ssh
  ]
  hostname         = local.target_name_test
  target_node      = var.iac_host_node
  ostemplate       = "${var.template_storage}:vztmpl/${local.ct_created_template_name}"
  password         = var.root_password
  unprivileged     = true
  cores            = 1
  memory           = 2048
  swap             = 4096
  nameserver       = "${var.vm_nameserver}"
  tags             = "terraform;test"
  vmid             = var.vm_id_test
  hastate          = "started"

  ssh_public_keys  = <<-EOT
      ${tls_private_key.ssh.public_key_openssh}
  EOT

  rootfs {
    storage        = var.lxc_storage
    size           = "8G"
  }

  network {
    name           = "eth0"
    bridge         = "vmbr0"
    ip             = "${var.vm_ipv4_cidr_test}"
    gw             = "${var.vm_gw4}"
    ip6            = ""
  }

  features {
    // fuse       = true
    nesting        = true
    // keyctl     = true
  }
}


resource "terraform_data" "test_vm" {

  triggers_replace = [
    proxmox_lxc.test_lxc.id
  ]

  connection {
    type           = "ssh"
    user           = "root"
    private_key    = chomp(tls_private_key.ssh.private_key_openssh)
    host           = var.vm_ipv4_test
  }

  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "echo Hello World!",
      "ansible --version",
      "tofu --version"
    ]
  }
}
