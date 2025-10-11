output "my_ip" {
  description = "IP address of the deployer host. Can be used to e.g. scope caller Security Groups"
  value       = "${chomp(data.http.my_ip.response_body)}/32"
}
