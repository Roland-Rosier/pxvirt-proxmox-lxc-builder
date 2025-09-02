locals {

  ct_containers_loc = chomp(templatefile("${path.module}/ct_containers_loc.tftpl", {
    template_storage_location     = var.template_storage_location
    template_storage              = var.template_storage
  }))

  ct_template_zip                 = "${local.ct_template_basename}.zip"
  ct_created_template_zip         = "${local.ct_created_template_basename}.zip"

}

resource "terraform_data" "extract_files" {

  triggers_replace = [
    timestamp(),
    terraform_data.test_vm.id
  ]

  depends_on = [
    terraform_data.shutdown_guest_and_backup
  ]

  provisioner "local-exec" {
    command        = "rm -rf ${var.asset_path}; mkdir -p ${var.asset_path}"
  }

  provisioner "local-exec" {
    command        = <<-EOT
      scp -i ~/.ssh/id_ed25519 -v root@${var.iac_host_ip}:${local.ct_containers_loc}/${local.ct_template_name} ${var.asset_path}/
      scp -i ~/.ssh/id_ed25519 -v root@${var.iac_host_ip}:${local.ct_containers_loc}/${local.ct_created_template_name} ${var.asset_path}/
    EOT
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
