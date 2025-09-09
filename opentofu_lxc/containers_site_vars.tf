# Where to download the containers from
variable "containers_url" {
  default = "https://images.linuxcontainers.org"
}

variable "containers_base_name" {
  type = string
  default = "linux-containers"
}

variable "containers_dist_name" {
  type = string
  default = "debian"
}

variable "containers_release_name" {
  type = string
  default = "bookworm"
}

variable "containers_arch_name" {
  type = string
  default = "arm64"
}

variable "containers_variant_name" {
  type = string
  default = "default"
}

variable "containers_base_date" {
  type = string
  default = "20250909"
}

variable "containers_update_date" {
  type = string
  default = "20250909"
}

variable "this_build_variant_name" {
  type = string
  default = "opentofu"
}

variable "containers_lxc_name" {
  type = string
  default = "rootfs"
}

variable "containers_lxc_name_extension" {
  type = string
  default = ".tar.xz"
}

variable "keep_downloaded_container" {
  default = true
}
