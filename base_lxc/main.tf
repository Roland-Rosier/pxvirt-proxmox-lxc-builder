locals {
  # Create the entire download location
  # Note: these are the templatefile function, not the template_file provider
  # https://developer.hashicorp.com/terraform/language/functions/templatefile
  container_url                   = chomp(templatefile("${path.module}/container_url.tftpl", {
    containers_url                = var.containers_url
    containers_dist_name          = var.containers_dist_name
    containers_release_name       = var.containers_release_name
    containers_arch_name          = var.containers_arch_name
    containers_variant_name       = var.containers_variant_name
    containers_date               = var.containers_date
    containers_time               = var.containers_time
    containers_lxc_name           = var.containers_lxc_name
    containers_lxc_name_extension = var.containers_lxc_name_extension
  }))

  # Create the CT template name that we are looking for
  ct_template_name                = chomp(templatefile("${path.module}/ct_template_name.tftpl", {
    containers_dist_name          = var.containers_dist_name
    containers_release_name       = var.containers_release_name
    containers_arch_name          = var.containers_arch_name
    containers_variant_name       = var.containers_variant_name
    containers_date               = var.containers_date
    containers_lxc_name           = var.containers_lxc_name
    containers_lxc_name_extension = var.containers_lxc_name_extension
  }))

  # Create the storage name of the provisioning snippet
  stored_provision_snippet        = "${var.target_name}-${var.provision_script_base_name}"

  # Create the snippet fully-qualified path in the storage
  stored_provision_snippet_path   = chomp(templatefile("${path.module}/snippet_loc.tftpl", {
    template_storage_location     = var.template_storage_location
    template_storage              = var.template_storage
    snippet_name                  = local.stored_provision_snippet
  }))

  # Define the location where the backup processing is performed
  backup_location = chomp(templatefile("${path.module}/download_base_image_loc.tftpl", {
    template_storage_location     = var.template_storage_location
    template_storage              = var.template_storage
    ct_template_name              = var.vm_id
  }))

  # Calculate today's date
  today_date                      = formatdate("YYYYMMDD", timestamp())

  # Create the CT template name that we are creating
  ct_created_template_basename    = chomp(templatefile("${path.module}/ct_template_name.tftpl", {
    containers_dist_name          = var.containers_dist_name
    containers_release_name       = var.containers_release_name
    containers_arch_name          = var.containers_arch_name
    containers_variant_name       = "${var.containers_variant_name}-base"
    containers_date               = "${var.containers_date}-${local.today_date}"
    containers_lxc_name           = var.containers_lxc_name
    containers_lxc_name_extension = ""
  }))

  ct_created_template_name        = "${local.ct_created_template_basename}.tar.xz"

  # Note, possibly the templatestring function would be more appropriate:
  # https://developer.hashicorp.com/terraform/language/functions/templatestring
}


resource "proxmox_lxc" "my_lxc" {
  depends_on       = [
    proxmox_virtual_environment_download_file.source_container
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

  rootfs {
    storage        = var.lxc_storage
    size           = "8G"
  }

  network {
    name           = var.nic_name
    bridge         = var.bridge_name
    # To create an image from one of the linuxcontainers built images,
    # * Enable only one network
    # * Leave the ip field empty
    # * Leave the gw field empty as well
    ip             = ""
    gw             = ""
    ip6            = ""
  }

  features {
    // fuse       = true
    nesting        = true
    // keyctl     = true
  }
}

resource "terraform_data" "create_files" {

  triggers_replace = [
    # timestamp()
    proxmox_lxc.my_lxc.id
  ]

  provisioner "local-exec" {
    command        = "mkdir -p 'created'"
  }

  provisioner "local-exec" {
    command        = <<-EOT
      cat > created/${var.provision_script_base_name} <<-CONFIG
      #!/bin/bash
      # Note - not using #!/usr/bin/env due to increased security risk
      set -euo pipefail
      cat > /etc/sysctl.d/10-disable-ipv6.conf <<-EOF
      # Disable ipv6
      net.ipv6.conf.all.disable_ipv6 = 1
      net.ipv6.conf.default.disable_ipv6 = 1
      EOF
      sysctl -p
      service procps force-reload

      cat > /etc/systemd/network/eth0.network <<-EOF
      ${var.nic_name}.network
      [Match]
      Name=${var.nic_name}

      [Network]
      Address=${var.vm_ipv4_cidr}
      Gateway=${var.vm_gw4}
      DNS=${var.vm_nameserver}
      EOF
      systemctl restart systemd-networkd

      sync
      sleep 1s

      apt-get update && apt-get upgrade -y && apt-get install -y ifupdown2 ssh screen tmux
      apt clean && apt autoremove

      systemctl stop systemd-networkd.socket systemd-networkd.service
      systemctl disable systemd-networkd.socket systemd-networkd.service
      systemctl mask systemd-networkd.socket systemd-networkd.service

      rm -f /etc/ssh/ssh_host_*

      sync
      sleep 1s

      truncate -s 0 /etc/machine-id

      cat /dev/null > ~/.bash_history && history -c && history -w && exit 0
      CONFIG
    EOT
  }

  provisioner "local-exec" {
    when           = destroy
    command        = "rm -rf created"
  }
}

# https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file
resource "proxmox_virtual_environment_file" "transfer_files_to_host" {
  provider         = proxmox-ot
  depends_on       = [
    terraform_data.create_files,
    proxmox_lxc.my_lxc
  ]
  content_type     = "snippets"
  datastore_id     = var.template_storage
  node_name        = var.iac_host_node
  overwrite        = true

  source_file {
    file_name      = "${var.target_name}-provision_lxc.sh"
    path           = "created/provision_lxc.sh"
  }
}

resource "terraform_data" "transfer_files_to_guest" {

  triggers_replace = [
    proxmox_virtual_environment_file.transfer_files_to_host.id
  ]

  # Remote exec probably won't work in guest because there is no SSH in guest
  # so use remote exec on host and pct
  connection {
    type           = "ssh"
    user           = "root"
    private_key    = file("~/.ssh/id_ed25519")
    host           = var.iac_host_ip
  }

  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "lxc-wait --name=${var.vm_id} --state=RUNNING",
      "pct push ${var.vm_id} ${local.stored_provision_snippet_path} /tmp/provision_lxc.sh -perms 4700",
      "pct exec ${var.vm_id} /tmp/provision_lxc.sh",
      "pct exec ${var.vm_id} -- bash -c 'rm -f /tmp/provision_lxc.sh'"      
    ]
  }

}

resource "terraform_data" "shutdown_guest_and_backup" {

  triggers_replace = [
    terraform_data.transfer_files_to_guest.id,
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

  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "pct shutdown ${var.vm_id}",
      "lxc-wait --name=${var.vm_id} --state=STOPPED",
      "mkdir -p ${local.backup_location}",
      "rm -f ${local.backup_location}/*",
      "vzdump ${var.vm_id} --mode stop --compress gzip --dumpdir ${local.backup_location}",
    ]
  }

  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "pushd ${local.backup_location}",
      "pwd",
      "BKFILE=$(basename -s .gz $(ls *.gz))",
      "gzip -dk $${BKFILE}.gz",
      "mv -v $${BKFILE} ${local.ct_created_template_basename}.tar",
      "popd",
    ]
  }

  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "pushd ${local.backup_location}",
      "pwd",
      "xz -9kT 0 ${local.ct_created_template_basename}.tar",
      "popd",
    ]
  }

  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "pushd ${local.backup_location}",
      "pwd",
      "cp -v ${local.ct_created_template_basename}.tar ${local.ct_created_template_basename}-e.tar",
      "xz -9ekT 0 ${local.ct_created_template_basename}-e.tar",
      "popd",
    ]
  }

  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "pushd ${local.backup_location}",
      "pwd",
      "FS_O=$(stat --format=%s ${local.ct_created_template_name})",
      "FS_E=$(stat --format=%s ${local.ct_created_template_basename}-e.tar.xz)",
      "if [ \"$${FS_E}\" -lt \"$${FS_O}\" ] ; then mv -fv ${local.ct_created_template_basename}-e.tar.xz ${local.ct_created_template_name} ; fi",
      "mv -fv ${local.ct_created_template_name} ../",
      "popd",
      "rm -rf ${local.backup_location}"
    ]
  }

}
