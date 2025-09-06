locals {

  # Define the location where the backup processing is performed
  backup_location = chomp(templatefile("${path.module}/download_base_image_loc.tftpl", {
    template_storage_location     = var.template_storage_location
    template_storage              = var.template_storage
    ct_template_name              = var.vm_id
  }))

}

resource "terraform_data" "shutdown_guest_and_backup" {

  triggers_replace = [
    terraform_data.transfer_files_to_guest.id
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
      "vzdump ${var.vm_id} --mode stop --dumpdir ${local.backup_location}"
    ]
    #   "vzdump ${var.vm_id} --mode stop --compress gzip --dumpdir ${local.backup_location}",
  }

  provisioner "remote-exec" {
    inline         = [
      "#!/bin/bash",
      "pushd ${local.backup_location}",
      "pwd",
      "BKFILE=$(ls *.tar)",
      "mv -v $${BKFILE} ${local.ct_created_template_basename}.tar",
      "popd"
    ]
    #   "BKFILE=$(basename -s .gz $(ls *.gz))",
    #   "gzip -dk $${BKFILE}.gz",
    #   "mv -v $${BKFILE} ${local.ct_created_template_basename}.tar",
  }

  # provisioner "remote-exec" {
  #   inline         = [
  #     "#!/bin/bash",
  #     "pushd ${local.backup_location}",
  #     "pwd",
  #     "xz -9kT 0 ${local.ct_created_template_basename}.tar",
  #     "popd",
  #   ]
  # }

  # provisioner "remote-exec" {
  #   inline         = [
  #     "#!/bin/bash",
  #     "pushd ${local.backup_location}",
  #     "pwd",
  #     "cp -v ${local.ct_created_template_basename}.tar ${local.ct_created_template_basename}-e.tar",
  #     "xz -9ekT 0 ${local.ct_created_template_basename}-e.tar",
  #     "popd",
  #   ]
  # }

  # provisioner "remote-exec" {
  #   inline         = [
  #     "#!/bin/bash",
  #     "pushd ${local.backup_location}",
  #     "pwd",
  #     "FS_O=$(stat --format=%s ${local.ct_created_template_name})",
  #     "FS_E=$(stat --format=%s ${local.ct_created_template_basename}-e.tar.xz)",
  #     "if [ \"$${FS_E}\" -lt \"$${FS_O}\" ] ; then mv -fv ${local.ct_created_template_basename}-e.tar.xz ${local.ct_created_template_name} ; fi",
  #     "mv -fv ${local.ct_created_template_name} ../",
  #     "popd",
  #     "rm -rf ${local.backup_location}"
  #   ]
  # }

}
