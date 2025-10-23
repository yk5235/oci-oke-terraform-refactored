# ============================================
# BASTION MODULE OUTPUTS
# ============================================

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = oci_core_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = oci_core_instance.bastion.private_ip
}

output "bastion_instance_id" {
  description = "OCID of the bastion instance"
  value       = oci_core_instance.bastion.id
}

output "bastion_subnet_id" {
  description = "OCID of the bastion subnet"
  value       = var.create_bastion_subnet ? oci_core_subnet.bastion_subnet[0].id : var.existing_subnet_id
}

output "bastion_subnet_cidr" {
  description = "CIDR block of the bastion subnet"
  value       = var.create_bastion_subnet ? oci_core_subnet.bastion_subnet[0].cidr_block : "Using existing subnet"
}

output "ssh_connection_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i <private_key_file> opc@${oci_core_instance.bastion.public_ip}"
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command for accessing private resources"
  value       = "ssh -i <private_key_file> -L 6443:<api_private_ip>:6443 opc@${oci_core_instance.bastion.public_ip}"
}

output "bastion_setup_status" {
  description = "Instructions for checking bastion setup status"
  value = {
    check_logs     = "ssh opc@${oci_core_instance.bastion.public_ip} 'sudo tail -f /var/log/bastion-setup.log'"
    check_complete = "ssh opc@${oci_core_instance.bastion.public_ip} 'ls -la /var/log/bastion-setup-complete'"
    get_kubeconfig = "scp opc@${oci_core_instance.bastion.public_ip}:~/.kube/config ./kubeconfig"
  }
}

output "connection_details" {
  description = "Detailed connection information"
  value = {
    host              = oci_core_instance.bastion.public_ip
    user              = "opc"
    private_ip        = oci_core_instance.bastion.private_ip
    availability_domain = oci_core_instance.bastion.availability_domain
    shape             = var.bastion_shape
    tools_installed   = ["docker", "kubectl", "oci-cli", "helm", "k9s", "stern"]
    sample_app_path   = "/home/opc/customer-management-app"
  }
}

output "bastion_metadata" {
  description = "Bastion instance metadata"
  value = {
    display_name = var.bastion_display_name
    created_at   = oci_core_instance.bastion.time_created
    region       = var.region
    compartment  = var.compartment_id
    tags         = var.tags
  }
}
