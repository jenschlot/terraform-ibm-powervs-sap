#####################################################
# Download collections from ansible galaxy and install HANA
#####################################################

locals {
  source_ansible_hana_vars_location = "${path.module}/ansible_default_hana_vars.yml"
  dest_ansible_hana_vars_location   = "/root/ansible_default_hana_vars.yml"
}

resource "null_resource" "sap_hana_install" {
  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = var.access_host_or_ip
    host         = var.target_server_ip
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "5m"
  }

  provisioner "file" {
    source      = local.source_ansible_hana_vars_location
    destination = local.dest_ansible_hana_vars_location
  }

  ##### Update the hana installation variables in ansible var file.
  provisioner "remote-exec" {
    inline = [

      "grep -qxF \"sap_hana_install_software_directory: ${var.ansible_sap_hana_install["software_directory"]}\" ${local.dest_ansible_hana_vars_location} || sed -i '/^sap_hana_install_software_directory:/csap_hana_install_software_directory: ${var.ansible_sap_hana_install["software_directory"]}' ${local.dest_ansible_hana_vars_location}",
      "grep -qxF \"sap_hana_install_master_password: ${var.ansible_sap_hana_install["master_password"]}\" ${local.dest_ansible_hana_vars_location} || sed -i '/^sap_hana_install_master_password:/csap_hana_install_master_password: \"${var.ansible_sap_hana_install["master_password"]}\"' ${local.dest_ansible_hana_vars_location}",
      "grep -qxF \"sap_hana_install_sid: ${var.ansible_sap_hana_install["sid"]}\" ${local.dest_ansible_hana_vars_location} || sed -i '/^sap_hana_install_sid:/csap_hana_install_sid: \"${var.ansible_sap_hana_install["sid"]}\"' ${local.dest_ansible_hana_vars_location}",
      "grep -qxF \"sap_hana_install_instance_number: ${var.ansible_sap_hana_install["instance_number"]}\" ${local.dest_ansible_hana_vars_location} || sed -i '/^sap_hana_install_instance_number:/csap_hana_install_instance_number: \"${var.ansible_sap_hana_install["instance_number"]}\"' ${local.dest_ansible_hana_vars_location}",
    ]
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
