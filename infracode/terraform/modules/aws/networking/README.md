AWS VPC & related resources
===========================

This is an opinionated Terraform module that creates an AWS VPC, as many public
& private subnets as there are AZs in a Region, and all the other fixin's (like
a NAT Gateway, routes, yadda yadda).

The VPC's CIDR block is `10.0.0.0/16`, with `/24` subnets incrementing the
second octet by one, starting with the public subnets. For example, in an AWS
Region with two AZs, the public subnet CIDRs would be `10.0.{1,2}.0/24`, and the
private subnet CIDRs would be `10.0.{3,4}.0/24`.
