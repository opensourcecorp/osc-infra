## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.61.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 2.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_network_interface.static_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.deployer_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_spot_instance_request.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/spot_instance_request) | resource |
| [aws_ami.latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_security_group.common](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnets.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [http_http.my_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Friendly name of application/platform being built | `string` | n/a | yes |
| <a name="input_desired_private_ip"></a> [desired\_private\_ip](#input\_desired\_private\_ip) | Desired private IP to associate to the instance. Must also specify use\_static\_ip = true | `string` | `""` | no |
| <a name="input_instance_profile_name"></a> [instance\_profile\_name](#input\_instance\_profile\_name) | Name of the IAM Instance Profile to attach to the instance | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | AWS EC2 instance type | `string` | n/a | yes |
| <a name="input_is_osc_core"></a> [is\_osc\_core](#input\_is\_osc\_core) | Whether the deployment represent core OSC infrastructure. Defaults to 'false' to prevent accidental misrepresenation | `bool` | `false` | no |
| <a name="input_keypair_name"></a> [keypair\_name](#input\_keypair\_name) | Name of SSH Keypair used to connect to the instance | `string` | `""` | no |
| <a name="input_name_tag"></a> [name\_tag](#input\_name\_tag) | Value for 'Name' tags | `string` | n/a | yes |
| <a name="input_sg_rules_maplist"></a> [sg\_rules\_maplist](#input\_sg\_rules\_maplist) | List-Map of custom Security Group Rules for the application/platform | `list(any)` | `[]` | no |
| <a name="input_source_address"></a> [source\_address](#input\_source\_address) | URI to the source of the code that actually calls this module | `string` | n/a | yes |
| <a name="input_source_ami_filter"></a> [source\_ami\_filter](#input\_source\_ami\_filter) | String pattern used in filtering the source AMI name | `string` | `"*ymir*"` | no |
| <a name="input_subnet_cidr_filter"></a> [subnet\_cidr\_filter](#input\_subnet\_cidr\_filter) | Optional CIDR block filter for finding a subnet to launch the instance into. This helps ensure your desired\_private\_ip will successfully attach | `string` | `""` | no |
| <a name="input_subnet_name_filter"></a> [subnet\_name\_filter](#input\_subnet\_name\_filter) | Name Tag filter for finding a subnet to launch the instance into | `string` | `"osc_public"` | no |
| <a name="input_use_spot_instance"></a> [use\_spot\_instance](#input\_use\_spot\_instance) | Whether or not to use EC2 Spot Instances | `bool` | `true` | no |
| <a name="input_use_static_ip"></a> [use\_static\_ip](#input\_use\_static\_ip) | Whether to assign a static IP (EIP) to the instance. When setting this to true, can also optionally specify desired\_private\_ip | `bool` | `false` | no |
| <a name="input_user_data_filepath"></a> [user\_data\_filepath](#input\_user\_data\_filepath) | Path to file containing a user data script to be run at first boot | `string` | `""` | no |
| <a name="input_user_data_string"></a> [user\_data\_string](#input\_user\_data\_string) | Command(s) to be run at first boot. If more than a single command, consider passing the 'user\_data\_filepath' variable instead | `string` | `"salt-call state.apply"` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | Size of root volume, in GiB | `number` | `16` | no |
| <a name="input_vpc_name_filter"></a> [vpc\_name\_filter](#input\_vpc\_name\_filter) | Name Tag filter for finding a VPC to launch the instance resources into | `string` | `"osc"` | no |

## Outputs

No outputs.
