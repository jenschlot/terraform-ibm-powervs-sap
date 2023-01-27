###########################################################
# Configure Squid client for internet services, Register OS
###########################################################

locals {
  scr_scripts_dir = "${path.module}/../terraform_templates"
  dst_scripts_dir = "/root/terraform_scripts"

  src_squid_setup_tpl_path      = "${local.scr_scripts_dir}/services_init.sh.tftpl"
  dst_squid_setup_path          = "${local.dst_scripts_dir}/services_init.sh"
  src_install_packages_tpl_path = "${local.scr_scripts_dir}/install_packages.sh.tftpl"
  dst_install_packages_path     = "${local.dst_scripts_dir}/install_packages.sh"

  ansible_connect_mgmt_svs_playbook_name     = "powervs-services.yml"
  ansible_configure_os_for_sap_playbook_name = var.os_image_distro == "SLES" ? "powervs-sles.yml" : var.os_image_distro == "RHEL" ? "powervs-rhel.yml" : "unknown"
  src_ansible_exec_tpl_path                  = "${local.scr_scripts_dir}/ansible_exec.sh.tftpl"
  dst_ansible_vars_connect_mgmt_svs_path     = "${local.dst_scripts_dir}/ansible_connect_to_mgmt_svs.yml"
  dst_ansible_vars_configure_os_for_sap_path = "${local.dst_scripts_dir}/ansible_configure_os_for_sap.yml"
}

resource "null_resource" "perform_proxy_client_setup" {

  count = var.perform_proxy_client_setup != null && var.perform_proxy_client_setup["enable"] == true ? length(var.target_server_ips) : 0

  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = var.access_host_or_ip
    host         = var.target_server_ips[count.index]
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      ####### Create Terraform scripts directory ############
      "mkdir -p ${local.dst_scripts_dir}",
      "chmod 777 ${local.dst_scripts_dir}",
    ]
  }

  provisioner "file" {
    destination = local.dst_squid_setup_path
    content = templatefile(
      local.src_squid_setup_tpl_path,
      {
        "proxy_ip_and_port" : var.perform_proxy_client_setup["server_ip_port"]
        "no_proxy_ip" : var.perform_proxy_client_setup["no_proxy_hosts"]
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      #######  Execute script: SQUID Forward PROXY CLIENT SETUP and OS Registration ############
      "chmod +x ${local.dst_squid_setup_path}",
      local.dst_squid_setup_path

    ]
  }
}


#####################################################
# Install Necessary Packages
#####################################################

resource "null_resource" "install_packages" {
  depends_on = [null_resource.perform_proxy_client_setup]
  count      = length(var.target_server_ips)

  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = var.access_host_or_ip
    host         = var.target_server_ips[count.index]
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      ####### Create Terraform scripts directory ############
      "mkdir -p ${local.dst_scripts_dir}",
      "chmod 777 ${local.dst_scripts_dir}",
    ]
  }

  provisioner "file" {
    destination = local.dst_install_packages_path
    content = templatefile(
      local.src_install_packages_tpl_path,
      {
        "install_packages" : true
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      #######  Execute script: Install packages ############
      "chmod +x ${local.dst_install_packages_path}",
      local.dst_install_packages_path

    ]
  }
}

#####################################################
# Execute Ansible galaxy role to prepare the system
#####################################################

resource "null_resource" "connect_to_mgmt_svs" {
  depends_on = [null_resource.install_packages]
  count      = length(var.target_server_ips)

  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = var.access_host_or_ip
    host         = var.target_server_ips[count.index]
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "5m"
  }

  provisioner "file" {

    #### Write the variables required for ansible roles to file  ####

    content = <<EOF
client_config : {
    squid : {
      enable : ${var.perform_proxy_client_setup["enable"]},
      squid_server_ip_port : '${var.perform_proxy_client_setup["server_ip_port"]}',
      no_proxy_hosts : '${var.perform_proxy_client_setup["no_proxy_hosts"]}'
    },
    ntp : {
      enable : ${var.perform_ntp_client_setup["enable"]},
      ntp_server_ip : '${var.perform_ntp_client_setup["server_ip"]}'
    },
    nfs : {
      enable : ${var.perform_nfs_client_setup["enable"]},
      nfs_server_path : '${var.perform_nfs_client_setup["nfs_server_path"]}',
      nfs_client_path : '${var.perform_nfs_client_setup["nfs_client_path"]}'
    },
    dns : {
      enable : ${var.perform_dns_client_setup["enable"]},
      dns_server_ip : '${var.perform_dns_client_setup["server_ip"]}'
    }
  }
EOF

    destination = local.dst_ansible_vars_connect_mgmt_svs_path
  }

  provisioner "file" {
    destination = "${local.dst_scripts_dir}/connect_to_mgmt_svs.sh"
    content = templatefile(
      local.src_ansible_exec_tpl_path,
      {
        "ansible_playbook_name" : local.ansible_connect_mgmt_svs_playbook_name
        "ansible_extra_vars_path" : local.dst_ansible_vars_connect_mgmt_svs_path
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      ####  Execute ansible role : powervs_client_enable_services  ####

      "chmod +x ${local.dst_scripts_dir}/connect_to_mgmt_svs.sh",
      "${local.dst_scripts_dir}/connect_to_mgmt_svs.sh"

    ]
  }
}


resource "null_resource" "configure_os_for_sap" {
  depends_on = [null_resource.connect_to_mgmt_svs]
  count      = length(var.target_server_ips)

  connection {
    type         = "ssh"
    user         = "root"
    bastion_host = var.access_host_or_ip
    host         = var.target_server_ips[count.index]
    private_key  = var.ssh_private_key
    agent        = false
    timeout      = "5m"
  }

  provisioner "file" {

    #### Write the disks wwns and other variables required for ansible roles to file under /root/tf_configure_for_sap.yml  ####

    content = <<EOF
disks_configuration : ${jsonencode({ for key, value in var.powervs_instance_storage_configs[count.index] : key => split(",", var.powervs_instance_storage_configs[count.index][key]) })}
sap_solution : '${var.sap_solutions[count.index]}'
sap_domain : '${var.sap_domain}'
EOF

    destination = local.dst_ansible_vars_configure_os_for_sap_path
  }

  provisioner "file" {
    destination = "${local.dst_scripts_dir}/configure_os_for_sap.sh"
    content = templatefile(
      local.src_ansible_exec_tpl_path,
      {
        "ansible_playbook_name" : local.ansible_configure_os_for_sap_playbook_name
        "ansible_extra_vars_path" : local.dst_ansible_vars_configure_os_for_sap_path
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      ####  Execute ansible roles: prepare_sles/rhel_sap, powervs_fs_creation and powervs_swap_creation  ####

      "chmod +x ${local.dst_scripts_dir}/configure_os_for_sap.sh",
      "${local.dst_scripts_dir}/configure_os_for_sap.sh"
    ]
  }

}
