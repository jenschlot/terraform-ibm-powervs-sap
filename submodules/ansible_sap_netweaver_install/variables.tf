variable "access_host_or_ip" {
  description = "Public IP of Bastion Host"
  type        = string
}

variable "target_server_ip" {
  description = "Private IP of PowerVS instance reachable from the access host."
  type        = string
}

variable "ssh_private_key" {
  description = "Private Key to configure Instance, Will not be uploaded to server."
  type        = string
  sensitive   = true
}

variable "ansible_sap_hana_install" {
  description = "HANA Installation parameters"
  type = object(
    {
      enable             = bool
      software_directory = string
      master_password    = string
      sid                = string
      instance_number    = string
    }
  )
}
