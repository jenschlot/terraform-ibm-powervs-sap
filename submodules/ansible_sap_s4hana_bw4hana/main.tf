#####################################################
# Download collections from ansible galaxy and install HANA
#####################################################

locals {

  dest_ansible_hana_vars_location      = "/root/ansible_default_hana_vars.yml"
  dest_ansible_netweaver_vars_location = "/root/ansible_default_s4hana_bw4hana_vars.yml"

  solution                     = var.ansible_parameters["solution"]
  hana_software_directory      = var.ansible_parameters["hana_software_directory"]
  solution_software_directory  = var.ansible_parameters["solution_software_directory"]
  hana_instance_sap_ip         = var.ansible_parameters["hana_instance_sap_ip"]
  hana_instance_hostname       = var.ansible_parameters["hana_instance_hostname"]
  db_master_password           = var.ansible_parameters["db_master_password"]
  db_sid                       = var.ansible_parameters["db_sid"]
  db_instance_number           = var.ansible_parameters["db_instance_number"]
  swpm_sid                     = var.ansible_parameters["swpm_sid"]
  swpm_pas_instance_nr         = var.ansible_parameters["swpm_pas_instance_nr"]
  swpm_ascs_instance_nr        = var.ansible_parameters["swpm_ascs_instance_nr"]
  swpm_ascs_instance_hostname  = var.ansible_parameters["swpm_ascs_instance_hostname"]
  swpm_fqdn                    = var.ansible_parameters["swpm_fqdn"]
  swpm_master_password         = var.ansible_parameters["swpm_master_password"]
  swpm_ddic_000_password       = var.ansible_parameters["swpm_ddic_000_password"]
  swpm_db_system_password      = var.ansible_parameters["swpm_db_system_password"]
  swpm_db_systemdb_password    = var.ansible_parameters["swpm_db_systemdb_password"]
  swpm_db_schema_abap          = var.ansible_parameters["swpm_db_schema_abap"]
  swpm_db_schema_abap_password = var.ansible_parameters["swpm_db_schema_abap_password"]
  swpm_db_sidadm_password      = var.ansible_parameters["swpm_db_sidadm_password"]

  product_catalog_map = {
    "s4hana"  = "NW_ABAP_OneHost:S4HANA2020.CORE.HDB.ABAP"
    "bw4hana" = "NW_ABAP_OneHost:BW4HANA20.CORE.HDB.ABAP"
  }

  catalog_id = lookup(local.product_catalog_map, local.solution)
}

resource "null_resource" "sap_hana_install" {
  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = var.access_host_or_ip
    host         = var.target_server_hana_ip
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "5m"
  }

  provisioner "file" {

    ######### Write the HANA installation variables in ansible var file. /root/ansible_default_hana_vars.yml ####

    content = <<EOF
# Install directory must contain
#   1.  IMDB_SERVER*SAR file
#   2.  IMDB_*SAR files for all components you wish to install
#   3.  SAPCAR executable
sap_hana_install_software_directory: '${local.hana_software_directory}'

# Master password
sap_hana_install_master_password: '${local.db_master_password}'

# Instance details
sap_hana_install_sid: '${local.db_sid}'
sap_hana_install_instance_number: '${local.db_instance_number}'
EOF

    destination = local.dest_ansible_hana_vars_location

  }


  provisioner "remote-exec" {
    inline = [

      ####  Execute ansible community role to install HANA.  ####
      "ansible-galaxy collection install ibm.power_linux_sap:1.0.9",
      "ansible-galaxy collection install community.sap_install:1.1.0",
      "unbuffer ansible-playbook --connection=local -i 'localhost,' ~/.ansible/collections/ansible_collections/community/sap_install/playbooks/sample-sap-hana-install.yml --extra-vars '@${local.dest_ansible_hana_vars_location}' 2>&1 | tee ansible_execution.log ",
    ]
  }
}

resource "null_resource" "sap_nw_install" {
  depends_on = [null_resource.sap_hana_install]
  count      = local.catalog_id != null ? 1 : 0
  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = var.access_host_or_ip
    host         = var.target_server_nw_ip
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "5m"
  }


  ### add HANA SAP host IP in /etc/hosts file
  provisioner "remote-exec" {
    inline = [
      "grep -qxF \"${local.hana_instance_sap_ip} ${local.hana_instance_hostname} ${local.hana_instance_hostname}.${local.swpm_fqdn} \" /etc/hosts || echo \"${local.hana_instance_sap_ip} ${local.hana_instance_hostname} ${local.hana_instance_hostname}.${local.swpm_fqdn}\" >> /etc/hosts"
    ]
  }

  provisioner "file" {

    ######### Write the netweaver installation variables in ansible var file. /root/ansible_default_s4hana_bw4hana_vars.yml ####

    content = <<EOF
# Product ID for New Installation
sap_swpm_product_catalog_id: '${local.catalog_id}'

# Software
sap_swpm_software_path: '${local.solution_software_directory}'
sap_swpm_sapcar_path: '${local.solution_software_directory}'
sap_swpm_swpm_path: '${local.solution_software_directory}'

# NW Passwords
sap_swpm_master_password: '${local.swpm_master_password}'
sap_swpm_ddic_000_password: '${local.swpm_ddic_000_password}'

# HDB Passwords
sap_swpm_db_system_password: '${local.swpm_db_system_password}'
sap_swpm_db_systemdb_password: '${local.swpm_db_systemdb_password}'
sap_swpm_db_schema_abap: '${local.swpm_db_schema_abap}'
sap_swpm_db_schema_abap_password: '${local.swpm_db_schema_abap_password}'
sap_swpm_db_sidadm_password: '${local.swpm_db_sidadm_password}'

# NW Instance Parameters
sap_swpm_sid: '${local.swpm_sid}'
sap_swpm_pas_instance_nr: '${local.swpm_pas_instance_nr}'
sap_swpm_ascs_instance_nr: '${local.swpm_ascs_instance_nr}'
sap_swpm_ascs_instance_hostname: '${local.swpm_ascs_instance_hostname}'
sap_swpm_fqdn: '${local.swpm_fqdn}'

# HDB Instance Parameters
# For dual host installation, change the db_host to appropriate value
sap_swpm_db_host: '${local.hana_instance_hostname}'
sap_swpm_db_sid: '${local.db_sid}'
sap_swpm_db_instance_nr: '${local.db_instance_number}'

EOF

    destination = local.dest_ansible_netweaver_vars_location
  }

  provisioner "remote-exec" {
    inline = [

      ####  Execute ansible community role to install S4HANA/BW$HANA based on solution passed.git   ####
      "ansible-galaxy collection install ibm.power_linux_sap:1.0.9",
      "ansible-galaxy collection install community.sap_install:1.1.0",
      #"unbuffer ansible-playbook --connection=local -i 'localhost,' ~/.ansible/collections/ansible_collections/community/sap_install/playbooks/sample-sap-hana-install.yml --extra-vars '@${local.dest_ansible_hana_vars_location}' 2>&1 | tee ansible_execution.log ",
    ]
  }
}
