locals {
  # Create the CT template name that we are looking for
  ct_template_basename            = chomp(templatefile("${path.module}/ct_template_name.tftpl", {
    containers_base_name          = var.containers_base_name
    containers_dist_name          = var.containers_dist_name
    containers_release_name       = var.containers_release_name
    containers_arch_name          = var.containers_arch_name
    containers_variant_name       = "${var.containers_variant_name}-base"
    containers_date               = "${var.containers_base_date}-${var.containers_update_date}"
    containers_lxc_name           = var.containers_lxc_name
    containers_lxc_name_extension = ""
  }))

  ct_template_name                = "${local.ct_template_basename}${var.containers_lxc_name_extension}"

  # Calculate today's date
  today_date                      = formatdate("YYYYMMDD", timestamp())

  # Create the CT template name that we are creating
  ct_created_template_basename    = chomp(templatefile("${path.module}/ct_template_name.tftpl", {
    containers_base_name          = var.containers_base_name
    containers_dist_name          = var.containers_dist_name
    containers_release_name       = var.containers_release_name
    containers_arch_name          = var.containers_arch_name
    containers_variant_name       = "${var.containers_variant_name}-${var.this_build_variant_name}"
    containers_date               = "${var.containers_base_date}-${local.today_date}"
    containers_lxc_name           = var.containers_lxc_name
    containers_lxc_name_extension = ""
  }))

  ct_created_template_name        = "${local.ct_created_template_basename}${var.containers_lxc_name_extension}"

  # Note, possibly the templatestring function would be more appropriate:
  # https://developer.hashicorp.com/terraform/language/functions/templatestring

  ssh_public_key_root            = chomp(file("/root/.ssh/id_ed25519.pub"))
}

resource "terraform_data" "ensure_iac_host_present_in_known_hosts" {

  provisioner "local-exec" {
    command = <<-EOT
      ssh-keygen -R ${var.iac_host_ip} || true
      ssh-keyscan ${var.iac_host_ip} >> ~/.ssh/known_hosts
    EOT
  }

}

resource "proxmox_lxc" "my_lxc" {
  depends_on       = [
  #   proxmox_virtual_environment_download_file.source_container
    terraform_data.ensure_iac_host_present_in_known_hosts
  ]
  hostname         = var.target_name
  target_node      = var.iac_host_node
  ostemplate       = "${var.template_storage}:vztmpl/${local.ct_template_name}"
  password         = var.root_password
  unprivileged     = true
  cores            = 1
  memory           = 2048
  swap             = 4096
  nameserver       = "${var.vm_nameserver}"
  tags             = "terraform;test"
  vmid             = var.vm_id
  hastate          = "started"

  ssh_public_keys  = local.ssh_public_key_root

  rootfs {
    storage        = var.lxc_storage
    size           = "8G"
  }

  network {
    name           = var.nic_name
    bridge         = var.bridge_name
    ip             = var.vm_ipv4_cidr
    gw             = var.vm_gw4
    ip6            = ""
  }

  features {
    // fuse       = true
    nesting        = true
    // keyctl     = true
  }
}

resource "terraform_data" "wait_for_guest_to_start" {

  triggers_replace = [
    proxmox_lxc.my_lxc.id
  ]

  # Remote exec probably won't work in guest because there is no SSH in guest
  # so use remote exec on host and pct
  connection {
    type           = "ssh"
    user           = "root"
    private_key    = file("~/.ssh/id_ed25519")
    host           = var.iac_host_ip
  }

  # Split these commands up to try and reduce the potential for
  # timeouts with multiple long compression calls

#      "pct shutdown ${var.vm_id}",
#      "mkdir -p ${local.backup_location}",
#      "rm -f ${local.backup_location}/*",
#      "vzdump ${var.vm_id} --mode stop --compress gzip --dumpdir ${local.backup_location}",
  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "lxc-wait --name=${var.vm_id} --state=RUNNING",
      "pct exec ${var.vm_id} -- bash -c 'while ! systemctl is-system-running | grep -qE \"running|degraded\" ; do sleep 1; done'",
      "sleep 20"
    ]
  }
}

resource "local_file" "tf_ansible_vars_file" {

  depends_on = [
    terraform_data.wait_for_guest_to_start
  ]

  # triggers_replace = [
  #   terraform_data.wait_for_guest_to_start.id
  # ]

  content = <<-DOC
    # Ansible vars generated containing variable values from Tofu

    tf_ansible_build_host_var: ${var.vm_ipv4}
  DOC
  filename = "./ansible/tf_ansible_vars_file.yml"
}

resource "terraform_data" "install_packages" {

  triggers_replace = [
    # timestamp()
    # proxmox_lxc.my_lxc.id
    # terraform_data.wait_for_guest_to_start.id
    local_file.tf_ansible_vars_file.id
  ]

  provisioner "local-exec" {
    command        = "cd ansible && ansible-playbook upgrade.yaml"
  }
}

# resource "ansible_playbook" "playbook" {

#  depends_on = [
    # timestamp()
#    proxmox_lxc.my_lxc
#  ]

#  playbook = "./ansible/upgrade.yaml"
#  name     = "localhost"
#}
