# ============================================
# NETWORKING MODULE OUTPUTS - REFACTORED
# ============================================

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_virtual_network.vcn.id
}

output "subnet_ids" {
  description = "Map of subnet names to their OCIDs"
  value = {
    for k, subnet in oci_core_subnet.subnets :
    k => subnet.id
  }
}

output "subnet_cidrs" {
  description = "Map of subnet names to their CIDR blocks"
  value = {
    for k, subnet in oci_core_subnet.subnets :
    k => subnet.cidr_block
  }
}

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway"
  value       = oci_core_nat_gateway.nat.id
}

output "service_gateway_id" {
  description = "OCID of the Service Gateway"
  value       = oci_core_service_gateway.svc.id
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = oci_core_internet_gateway.igw.id
}

output "route_table_ids" {
  description = "Map of route table names to their OCIDs"
  value = {
    for k, rt in oci_core_route_table.rt :
    k => rt.id
  }
}

output "security_list_ids" {
  description = "Map of security list names to their OCIDs"
  value = {
    for k, sl in oci_core_security_list.sl :
    k => sl.id
  }
}