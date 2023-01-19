# Module ansible_default_hana_install

This module calls ansible collection and install SAP HANA on target system.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.sap_hana_install](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_host_or_ip"></a> [access\_host\_or\_ip](#input\_access\_host\_or\_ip) | Public IP of Bastion Host | `string` | n/a | yes |
| <a name="input_ansible_sap_hana_install"></a> [ansible\_sap\_hana\_install](#input\_ansible\_sap\_hana\_install) | HANA Installation parameters | <pre>object(<br>    {<br>      enable             = bool<br>      software_directory = string<br>      master_password    = string<br>      sid                = string<br>      instance_number    = string<br>    }<br>  )</pre> | n/a | yes |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | Private Key to configure Instance, Will not be uploaded to server. | `string` | n/a | yes |
| <a name="input_target_server_ip"></a> [target\_server\_ip](#input\_target\_server\_ip) | Private IP of PowerVS instance reachable from the access host. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
