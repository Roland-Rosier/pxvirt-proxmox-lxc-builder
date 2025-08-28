locals {

  ct_containers_loc = chomp(templatefile("${path.module}/ct_containers_loc.tftpl", {
    template_storage_location     = var.template_storage_location
    template_storage              = var.template_storage
  }))

}

resource "terraform_data" "extract_files" {

  triggers_replace = [
    timestamp(),
    terraform_data.test_vm.id
    # terraform_data.shutdown_guest_and_backup.id
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

  # provisioner "local-exec" {
  #   when           = destroy
  #   command        = "rm -rf created"
  # }
}
