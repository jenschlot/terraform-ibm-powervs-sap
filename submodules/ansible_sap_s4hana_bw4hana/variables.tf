variable "access_host_or_ip" {
  description = "Public IP of Bastion Host"
  type        = string
}

variable "target_server_hana_ip" {
  description = "HANA Private IP of PowerVS instance reachable from the access host."
  type        = string
}

variable "target_server_nw_ip" {
  description = "Netweaver Private IP of PowerVS instance reachable from the access host."
  type        = string
}

variable "ssh_private_key" {
  description = "Private Key to configure Instance, Will not be uploaded to server."
  type        = string
  sensitive   = true
}

variable "ansible_parameters" {
  description = "HANA and S4HANA/BW4HANA Installation parameters"
  type = object(
    {
      enable                       = bool
      solution                     = string
      hana_software_directory      = string
      solution_software_directory  = string
      hana_instance_sap_ip         = string
      hana_instance_hostname       = string
      db_master_password           = string
      db_sid                       = string
      db_instance_number           = string
      swpm_sid                     = string
      swpm_pas_instance_nr         = string
      swpm_ascs_instance_nr        = string
      swpm_ascs_instance_hostname  = string
      swpm_fqdn                    = string
      swpm_master_password         = string
      swpm_ddic_000_password       = string
      swpm_db_system_password      = string
      swpm_db_systemdb_password    = string
      swpm_db_schema_abap          = string
      swpm_db_schema_abap_password = string
      swpm_db_sidadm_password      = string
    }
  )
}
