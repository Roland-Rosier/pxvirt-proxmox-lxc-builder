# Which IAC tool being used - terraform or tofu
variable "iac_tool" {
  default     = "tofu"
}

# Public SSH key
variable "ssh_key" {
  default     = ""
}

# Root password
variable root_password {
  description = "The root password - pass in as export TF_VAR_root_password='<password>'"
  type        = string
  sensitive   = true
}

# Establish which pxvirt / proxmox host to control resources on
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "iac_host_ip" {
  type        = string
}

# Which node to launch the container on
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "iac_host_node" {
  type        = string
}

# Storage used to hold the template (down download and created)
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "template_storage" {
  type        = string
}

# Storage used to hold the LXCs
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "lxc_storage" {
  type        = string
}

# Location of template storage in host filesystem
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "template_storage_location" {
  type        = string
}

# Establish which nic you would like to utilize
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "nic_name" {
  type        = string
}

# Establish which bridge you would like to utilize
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "bridge_name" {
  type        = string
}

# Establish the VLAN you'd like to use
# But there are no VLANs set up
# variable "vlan_num" {
#   default = "VLAN Number"
# }

# Provide the endpoint and url of the host you would like the API to communicate on.
# It is safe to default to setting this as the URL for what you used
# as your "pxvirt_host", although they can be different
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "api_endpoint" {
  type        = string
}

# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "api_url" {
  type        = string
}

# Provide the ID of the LXC / VM - used when creating the template
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "vm_id" {
  type        = number
}

# Provide the ID of the LXC / VM - used when testing the template
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "vm_id_test" {
  type        = number
}

# Provide the name of the LXC / VM itself - used when creating the template
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "target_name" {
  type        = string
}

# Provide the IPV4(CIDR) of the LXC / VM itself - used when creating the template
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "vm_ipv4_cidr" {
  type        = string
}

# Provide the IPV4(CIDR) of the LXC / VM itself - used when testing the template
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "vm_ipv4_cidr_test" {
  type        = string
}

# Provide the IPV4 (w/out /x) of the LXC / VM itself - used when testing the template
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "vm_ipv4_test" {
  type        = string
}

# Provide the IPV4 of the GW of the LXC / VM itself
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "vm_gw4" {
  type        = string
}

# Provide the IPV4 of the nameserver of the LXC / VM itself
# Not sensitive, but changes, so pass in as an env var, or in a .tfvars file
variable "vm_nameserver" {
  type        = string
}

# Directory to create files in
variable "created_files_dir" {
  type        = string
  default     = "created"
}

# Base name of the provisioning script
variable "provision_script_base_name" {
  type        = string
  default     = "provision_lxc.sh"
}

# Blank var for use by terraform.tfvars
variable "token_id" {
  type        = string
  sensitive   = true
}

# Blank var for use by terraform.tfvars
variable "token_secret" {
  type        = string
  sensitive   = true
}
