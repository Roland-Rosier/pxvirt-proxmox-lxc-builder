# Providers.tf - where the Providers are identifies
terraform {
  required_providers {
    # From: https://registry.terraform.io/providers/Telmate/proxmox/latest
    proxmox = {
      source          = "Telmate/proxmox"
      version         = "3.0.2-rc03"
    }
    proxmox-ot = {
      source          = "bpg/proxmox"
      version         = "0.81.0"
    }
    # From: https://registry.terraform.io/providers/hashicorp/external/latest
    # external = {
    #   source = "hashicorp/external"
    #   version = "2.3.5"
    # }
    null = {
      source          = "hashicorp/null"
      version         = "3.2.4"
    }
    tls = {
      source          = "hashicorp/tls"
      version         = "4.1.0"
    }
  }
}


provider "proxmox" {
  # References the vars.tf file
  pm_api_url          = var.api_url
  # References the terraform.tfvars file
  pm_api_token_id     = var.token_id
  # References the terraform.tfvars file
  pm_api_token_secret = var.token_secret
  # Default to 'true' unless you have TLS working
  pm_tls_insecure     = true
}

provider "proxmox-ot" {
  endpoint            = var.api_endpoint
  api_token           = "${var.token_id}=${var.token_secret}"
  insecure            = true
  ssh {
#    agent             = true
    agent             = false
    username          = "root"
    private_key       = file("~/.ssh/id_ed25519")
  }
}

# provider "external" {
# }

provider "null" {
}

provider "tls"{
}
