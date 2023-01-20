variable "ibmcloud_api_key" {
  description = "IBM Cloud Api Key"
  type        = string
  sensitive   = true
}

variable "prerequisite_workspace_id" {
  description = "IBM Cloud Schematics workspace ID of an existing Power infrastructure for regulated industries deployment. If you do not yet have an existing deployment, click [here](https://cloud.ibm.com/catalog/content/terraform-ibm-powervs-catalog-powervs-sap-infrastructure-07e92c55-6a5b-4f3d-aa0e-30212e108af9-global#create) to create one."
  type        = string
}

variable "powervs_zone" {
  description = "IBM Cloud data center location where IBM PowerVS infrastructure will be created."
  type        = string
}

variable "prefix" {
  description = "Unique prefix for resources to be created (e.g., SAP system name). Max length must be less than or equal to 6."
  type        = string
  validation {
    condition     = length(var.prefix) <= 6
    error_message = "Prefix length exceeds 6 characters"
  }
}

variable "ssh_private_key" {
  description = "Private SSH key (RSA format) used to login to IBM PowerVS instances. Should match to uploaded public SSH key referenced by 'ssh_public_key'. Entered data must be in [heredoc strings format](https://www.terraform.io/language/expressions/strings#heredoc-strings). The key is not uploaded or stored. For more information about SSH keys, see [SSH keys](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys)."
  type        = string
  sensitive   = true
}

variable "powervs_sap_network_cidr" {
  description = "Network range for separate SAP network. E.g., '10.111.1.0/24'"
  type        = string
  default     = "10.111.1.0/24"
}

variable "os_image_distro" {
  description = "Image distribution to use. Supported values are 'SLES' or 'RHEL'. OS release versions may be specified in optional parameters."
  type        = string
  default     = "RHEL"
}

#####################################################
# PowerVS Shared FS Instance parameters
#####################################################

variable "create_separate_fs_share" {
  description = "Deploy separate IBM PowerVS instance as central file system share. Instance can be configured in optional parameters (cpus, memory size, etc.). Otherwise, defaults will be used."
  type        = bool
  default     = false
}

#####################################################
# PowerVS HANA Instance parameters
#####################################################

variable "sap_hana_hostname" {
  description = "SAP HANA hostname (non FQDN). Will get the form of <prefix>-<sap_hana_hostname>. Max length of final hostname must be <= 13 characters."
  type        = string
  default     = "hana"
}

variable "sap_hana_profile" {
  description = "SAP HANA profile to use. Must be one of the supported profiles. See [here](https://cloud.ibm.com/docs/sap?topic=sap-hana-iaas-offerings-profiles-power-vs). File system sizes are automatically calculated. Override automatic calculation by setting values in optional sap_hana_custom_storage_config parameter."
  type        = string
  default     = "cnp-4x128"
}

variable "sap_hana_additional_storage_config" {
  description = "Additional File systems to be created and attached to PowerVS instance for SAP HANA. 'disk_sizes' are in GB. 'count' specify over how many storage volumes the file system will be striped. 'tiers' specifies the storage tier in PowerVS workspace. For creating multiple file systems, specify multiple entries in each parameter in the structure. E.g., for creating 2 file systems, specify 2 names, 2 disk sizes, 2 counts, 2 tiers and 2 paths."
  type = object({
    names      = string
    disks_size = string
    counts     = string
    tiers      = string
    paths      = string
  })
  default = {
    names      = "usrsap"
    disks_size = "50"
    counts     = "1"
    tiers      = "tier3"
    paths      = "/usr/sap"
  }
}

#####################################################
# PowerVS NetWeaver Instance parameters
#####################################################

variable "sap_netweaver_hostname" {
  description = "SAP Netweaver hostname (non FQDN). Will get the form of <prefix>-<sap_netweaver_hostname>-<number>. Max length of final hostname must be <= 13 characters."
  type        = string
  default     = "nw"
}

variable "sap_netweaver_cpu_number" {
  description = "Number of CPUs for each SAP NetWeaver instance."
  type        = string
  default     = "3"
}

variable "sap_netweaver_memory_size" {
  description = "Memory size for each SAP NetWeaver instance."
  type        = string
  default     = "32"
}

#####################################################
# PVS SAP Software Installation
#####################################################

variable "sap_domain" {
  description = "SAP domain to be set for entire landscape. Set to null or empty if not configuring OS."
  type        = string
}

variable "nfs_client_directory" {
  description = "NFS directory on PowerVS instances. Will be used only if nfs_server is setup in 'Power infrastructure for regulated industries'"
  type        = string
  default     = "/nfs"
}

variable "cos_config" {
  description = "COS bucket access information to copy the SAP Software to LOCAL DISK."
  type = object(
    {
      cos_bucket_name                 = string
      cos_access_key                  = string
      cos_secret_access_key           = string
      cos_endpoint_url                = string
      cos_hana_software_directory     = string
      cos_solution_software_directory = string
    }
  )
}

#####################################################
# PVS SAP HANA Ansible Parameters
#####################################################
variable "ansible_sap_solution" {
  description = "HANA Installation parameters"
  type = object(
    {
      solution                     = string
      db_master_password           = string
      db_sid                       = string
      db_instance_number           = string
      swpm_sid                     = string
      swpm_pas_instance_nr         = string
      swpm_ascs_instance_nr        = string
      swpm_master_password         = string
      swpm_ddic_000_password       = string
      swpm_db_system_password      = string
      swpm_db_systemdb_password    = string
      swpm_db_schema_abap          = string
      swpm_db_schema_abap_password = string
      swpm_db_sidadm_password      = string
    }
  )
  default = {
    solution                     = "s4hana"
    db_master_password           = "NewPass$321"
    db_sid                       = "HDB"
    db_instance_number           = "00"
    swpm_sid                     = "S4H"
    swpm_pas_instance_nr         = "01"
    swpm_ascs_instance_nr        = "02"
    swpm_master_password         = "NewPass$321"
    swpm_ddic_000_password       = "NewPass$321"
    swpm_db_system_password      = "NewPass$321"
    swpm_db_systemdb_password    = "NewPass$321"
    swpm_db_schema_abap          = "SAPHANADB"
    swpm_db_schema_abap_password = "NewPass$321"
    swpm_db_sidadm_password      = "NewPass$321"
  }

  validation {
    condition     = contains(["s4hana", "bw4hana"], var.ansible_sap_solution["solution"]) ? true : false
    error_message = "Solution value has to be either s4hana or bw4hana"
  }
}

#####################################################
# Optional Parameters
#####################################################

variable "default_hana_sles_image" {
  description = "Default SuSE Linux image to use for SAP HANA PowerVS instances."
  type        = string
  default     = "SLES15-SP3-SAP"
}

variable "default_netweaver_sles_image" {
  description = "Default SuSE Linux image to use for SAP NetWeaver PowerVS instances."
  type        = string
  default     = "SLES15-SP3-SAP-NETWEAVER"
}

variable "default_shared_fs_sles_image" {
  description = "Default SuSE Linux image to use for SAP shared FS PowerVS instances"
  type        = string
  default     = "SLES15-SP3-SAP-NETWEAVER"
}

variable "default_hana_rhel_image" {
  description = "Default Red Hat Linux image to use for SAP HANA PowerVS instances."
  type        = string
  default     = "RHEL8-SP4-SAP"
}

variable "default_netweaver_rhel_image" {
  description = "Default Red Hat Linux image to use for SAP NetWeaver PowerVS instances."
  type        = string
  default     = "RHEL8-SP4-SAP-NETWEAVER"
}

variable "default_shared_fs_rhel_image" {
  description = "Default Red Hat Linux image to use for SAP shared FS PowerVS instances."
  type        = string
  default     = "RHEL8-SP4-SAP-NETWEAVER"
}

variable "sap_share_instance_config" {
  description = "SAP shared file system PowerVS instance configuration. If data is specified here - will replace other input."
  type = object({
    os_image_name        = string
    number_of_processors = string
    memory_size          = string
    cpu_proc_type        = string
    server_type          = string
  })
  default = {
    os_image_name        = ""
    number_of_processors = "0.5"
    memory_size          = "4"
    cpu_proc_type        = "shared"
    server_type          = "s922"
  }
}

variable "sap_share_storage_config" {
  description = "File systems to be created and attached to PowerVS instance for shared storage file systems. 'disk_sizes' are in GB. 'count' specify over how many storage volumes the file system will be striped. 'tiers' specifies the storage tier in PowerVS workspace. For creating multiple file systems, specify multiple entries in each parameter in the structure. E.g., for creating 2 file systems, specify 2 names, 2 disk sizes, 2 counts, 2 tiers and 2 paths."
  type = object({
    names      = string
    disks_size = string
    counts     = string
    tiers      = string
    paths      = string
  })
  default = {
    names      = "share"
    disks_size = "1000"
    counts     = "1"
    tiers      = "tier3"
    paths      = "/share"
  }
}

variable "sap_hana_instance_config" {
  description = "SAP HANA PowerVS instance configuration. If data is specified here - will replace other input."
  type = object({
    os_image_name  = string
    sap_profile_id = string
  })
  default = {
    os_image_name  = ""
    sap_profile_id = ""
  }
}

variable "sap_hana_custom_storage_config" {
  description = "Custom File systems to be created and attached to PowerVS instance for SAP HANA. 'disk_sizes' are in GB. 'count' specify over how many storage volumes the file system will be striped. 'tiers' specifies the storage tier in PowerVS workspace. For creating multiple file systems, specify multiple entries in each parameter in the structure. E.g., for creating 2 file systems, specify 2 names, 2 disk sizes, 2 counts, 2 tiers and 2 paths."
  type = object({
    names      = string
    disks_size = string
    counts     = string
    tiers      = string
    paths      = string
  })
  default = {
    names      = ""
    disks_size = ""
    counts     = ""
    tiers      = ""
    paths      = ""
  }
}

variable "sap_netweaver_instance_config" {
  description = "SAP NetWeaver PowerVS instance configuration. If data is specified here - will replace other input."
  type = object({
    os_image_name        = string
    number_of_processors = string
    memory_size          = string
    cpu_proc_type        = string
    server_type          = string
  })
  default = {
    os_image_name        = ""
    number_of_processors = ""
    memory_size          = ""
    cpu_proc_type        = "shared"
    server_type          = "s922"
  }
}

variable "sap_netweaver_storage_config" {
  description = "File systems to be created and attached to PowerVS instance for SAP NetWeaver. 'disk_sizes' are in GB. 'count' specify over how many storage volumes the file system will be striped. 'tiers' specifies the storage tier in PowerVS workspace. For creating multiple file systems, specify multiple entries in each parameter in the structure. E.g., for creating 2 file systems, specify 2 names, 2 disk sizes, 2 counts, 2 tiers and 2 paths."
  type = object({
    names      = string
    disks_size = string
    counts     = string
    tiers      = string
    paths      = string
  })
  default = {
    names      = "usrsap,usrtrans"
    disks_size = "50,50"
    counts     = "1,1"
    tiers      = "tier3,tier3"
    paths      = "/usr/sap,/usr/sap/trans"
  }
}
