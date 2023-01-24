#####################################################
# Download collections from ansible galaxy and install HANA & Netweaver
#####################################################

locals {

  dest_ansible_hana_vars_location      = "/root/ansible_default_hana_vars.yml"
  dest_ansible_netweaver_vars_location = "/root/ansible_default_s4hana_bw4hana_vars.yml"
  nw_hostname                          = var.ansible_parameters["netweaver_instance_hostname"]
  hana_hostname                        = var.ansible_parameters["hana_instance_hostname"]
  hana_sap_ip                          = var.ansible_parameters["hana_instance_sap_ip"]
  fqdn                                 = var.ansible_parameters["netweaver_ansible_vars"]["sap_swpm_fqdn"]
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

${yamlencode(var.ansible_parameters["hana_ansible_vars"])}
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
  # echo sap_ip hana_hostname hana_hostname.fqdn
  provisioner "remote-exec" {
    inline = [
      "grep -qxF \"${local.hana_sap_ip} ${local.hana_hostname} ${local.hana_hostname}.${local.fqdn}\" /etc/hosts || echo \"${local.hana_sap_ip} ${local.hana_hostname} ${local.hana_hostname}.${local.fqdn}\" >> /etc/hosts"
    ]
  }

  provisioner "file" {

    ######### Write the netweaver installation variables in ansible var file. /root/ansible_default_s4hana_bw4hana_vars.yml ####

    content = <<EOF
${yamlencode(var.ansible_parameters["netweaver_ansible_vars"])}
sap_swpm_ascs_instance_hostname: '${local.nw_hostname}'
sap_swpm_db_host: '${local.hana_hostname}'

EOF

    destination = local.dest_ansible_netweaver_vars_location
  }

  provisioner "remote-exec" {
    inline = [

      ####  Execute ansible community role to install S4HANA/BW4HANA based on solution passed.git   ####
      "ansible-galaxy collection install ibm.power_linux_sap:1.0.9",
      "ansible-galaxy collection install community.sap_install:1.1.0",
      "ansible-galaxy collection install community.general:6.2.0",
      "unbuffer ansible-playbook --connection=local -i 'localhost,' ~/.ansible/collections/ansible_collections/community/sap_install/playbooks/sample-sap-swpm.yml --extra-vars '@${local.dest_ansible_netweaver_vars_location}' 2>&1 | tee ansible_execution.log ",
    ]
  }
}
