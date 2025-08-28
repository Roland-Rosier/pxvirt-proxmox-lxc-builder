locals {
  # Create the image location of the image we are looking for
  ct_template_location = chomp(templatefile("${path.module}/download_base_image_loc.tftpl", {
    template_storage_location = var.template_storage_location
    template_storage = var.template_storage
    ct_template_name = local.ct_template_name
  }))

  resource_removal_message  = <<-EOT
  IMPORTANT:
    To avoid automatically deleting ${local.ct_template_name}
    Run:
      ${var.iac_tool} state rm proxmox_virtual_environment_download_file.source_container[0]

  Before running ${var.iac_tool} apply or destroy
  EOT
  # Note, possibly the templatestring function would be more appropriate:
  # https://developer.hashicorp.com/terraform/language/functions/templatestring
}

# Check to see if the base source container rootfs is already present
data "external" "source_build_present" {
  program = [
    "ssh",
    "root@${var.iac_host_ip}",
    "-i",
    "~/.ssh/id_ed25519",
    "if [[ -e ${local.ct_template_location} ]]; then echo '{ \"present\": \"true\" }'; else echo '{ \"present\": \"false\" }'; fi"
  ]

}
 
output "external_source_build_present" {
  # value = data.external.source_build_present.program
  value             = chomp(data.external.source_build_present.result.present)
}

resource "terraform_data" "needs_source_container" {
  input = chomp(data.external.source_build_present.result.present) == "true" ? false : true
}

resource "proxmox_virtual_environment_download_file" "source_container" {
  # count               = terraform_data.needs_source_container.output ? 0 : 1
  count = chomp(data.external.source_build_present.result.present) == "true" ? 0 : 1
  provider            = proxmox-ot
  content_type        = "vztmpl"
  datastore_id        = var.template_storage
  file_name           = local.ct_template_name
  node_name           = var.iac_host_node
  url                 = local.container_url
  overwrite           = false
  overwrite_unmanaged = false

  # lifecycle {
  #   prevent_destroy = var.keep_downloaded_container
  # }
}

output "terraform_data_release_ve_download_file" {
  depends_on        = [
    terraform_data.needs_source_container
  ]
  value             = terraform_data.needs_source_container.output ? local.resource_removal_message : ""
}
