output "access_host_or_ip" {
  description = "Public IP to manage the environment"
  value       = var.access_host_or_ip
}

output "hana_instance_private_ips" {
  description = "Private IPs of the HANA instance."
  value       = module.sap_hana_instance.instance_private_ips
}

output "hana_instance_private_mgmt_ip" {
  description = "Private Management IP of the HANA instance."
  value       = module.sap_hana_instance.instance_mgmt_ip
}

output "hana_instance_private_sap_ip" {
  description = "Private SAP IP of the HANA instance."
  value       = module.sap_hana_instance.instance_sap_ip
}

output "netweaver_instance_private_ips" {
  description = "Private IPs of all NetWeaver instances."
  value       = module.sap_netweaver_instance[*].instance_private_ips
}

output "share_fs_instance_private_ips" {
  description = "Private IPs of the Share FS instance."
  value       = length(module.share_fs_instance[*].instance_private_ips) != 0 ? module.share_fs_instance[*].instance_private_ips : null
}
