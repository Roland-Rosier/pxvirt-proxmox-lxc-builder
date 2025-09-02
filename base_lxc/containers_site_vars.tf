# Where to download the containers from
variable "containers_url" {
  default = "https://images.linuxcontainers.org"
}

variable "containers_dist_name" {
  default = "debian"
}

variable "containers_release_name" {
  default = "bookworm"
}

variable "containers_arch_name" {
  default = "arm64"
}

variable "containers_variant_name" {
  default = "default"
}

variable "containers_date" {
  default = "20250829"
}

variable "containers_time" {
  default = "05:44"
}

variable "containers_lxc_name" {
  default = "rootfs"
}

variable "containers_lxc_name_extension" {
  default = ".tar.xz"
}

variable "keep_downloaded_container" {
  default = true
}
