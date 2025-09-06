locals {

  ct_containers_loc = chomp(templatefile("${path.module}/ct_containers_loc.tftpl", {
    template_storage_location     = var.template_storage_location
    template_storage              = var.template_storage
  }))

  ct_template_zip                 = "${local.ct_template_basename}.zip"
  ct_created_template_tar         = "${local.ct_created_template_basename}.tar"
  ct_created_template_zip         = "${local.ct_created_template_basename}.zip"

  ct_template_name_loc            = "${local.ct_containers_loc}/${local.ct_template_name}"
  ct_created_template_t_loc       = "${local.backup_location}/${local.ct_created_template_tar}"

}

resource "terraform_data" "extract_files" {

  triggers_replace = [
    # timestamp(),
    # terraform_data.test_vm.id
    terraform_data.shutdown_guest_and_backup.id
  ]

  depends_on = [
    terraform_data.shutdown_guest_and_backup
  ]

  provisioner "local-exec" {
    command        = "rm -rf ${var.asset_path}; mkdir -p ${var.asset_path}"
  }

  provisioner "local-exec" {
    command        = <<-EOT
      scp -i ~/.ssh/id_ed25519 -v root@${var.iac_host_ip}:${local.ct_template_name_loc} ${var.asset_path}/
      scp -i ~/.ssh/id_ed25519 -v root@${var.iac_host_ip}:${local.ct_created_template_t_loc} ${var.asset_path}/
    EOT
  }

  # xz with compression at 9 and 9e can take over 674MiB per thread
  # this is quite a lot if multiple threads are used, so limit
  # threads to 1 but use the +1 notation to put it into multithreaded
  # compression mode so that decompression can be quick.
  provisioner "local-exec" {
    command        = <<-EOT
      xz -9kT +1 ${local.ct_created_template_basename}.tar
    EOT
    working_dir    = var.asset_path
  }

  provisioner "local-exec" {
    command        = <<-EOT
      cp -v ${local.ct_created_template_basename}.tar ${local.ct_created_template_basename}-e.tar
      xz -9eT +1 ${local.ct_created_template_basename}-e.tar
    EOT
    working_dir    = var.asset_path
    # interpreter    = [ "/bin/bash", "-c" ]
  }

  provisioner "local-exec" {
    command        = <<-EOT
      rm -rf tmp
      mkdir -p tmp
      cp ${local.ct_created_template_name} tmp
      cp ${local.ct_created_template_basename}-e.tar.xz tmp
    EOT
    working_dir    = var.asset_path
  }

  provisioner "local-exec" {
    command        = <<-EOT
      FS_O=$(stat --format=%s ${local.ct_created_template_name})
      FS_E=$(stat --format=%s ${local.ct_created_template_basename}-e.tar.xz)
      if [ "$${FS_E}" -lt "$${FS_O}" ] ; then mv -fv ${local.ct_created_template_basename}-e.tar.xz ${local.ct_created_template_name} ; fi
    EOT 
      # "mv -fv ${local.ct_created_template_name} ../"
    working_dir    = var.asset_path
  }

  provisioner "local-exec" {
    command        = <<-EOT
      zip -9v ${local.ct_template_zip} ${local.ct_template_name}
      zip -9v ${local.ct_created_template_zip} ${local.ct_created_template_name}
    EOT
    working_dir    = var.asset_path
  }

  # provisioner "local-exec" {
  #   when           = destroy
  #   command        = "rm -rf created"
  # }

}

resource "proxmox_virtual_environment_file" "ct_template" {
  provider         = proxmox-ot
  depends_on = [
    terraform_data.extract_files
  ]
  content_type     = "vztmpl"
  datastore_id     = var.template_storage
  node_name        = var.iac_host_node
  overwrite        = true
  source_file {
    path           = "${var.asset_path}/${local.ct_created_template_name}"
  }
}
