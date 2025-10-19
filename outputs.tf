# ============================================
# ROOT OUTPUTS - REFACTORED
# ============================================

# ============================================
# NETWORKING OUTPUTS
# ============================================

output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.networking.vcn_id
}

output "subnet_ids" {
  description = "Map of subnet names to their OCIDs"
  value       = module.networking.subnet_ids
}

output "subnet_cidrs" {
  description = "Map of subnet names to their CIDR blocks"
  value       = module.networking.subnet_cidrs
}

# ============================================
# OKE OUTPUTS
# ============================================

output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = module.oke.cluster_id
}

output "cluster_name" {
  description = "Name of the OKE cluster"
  value       = module.oke.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.oke.cluster_endpoint
}

output "node_pool_id" {
  description = "OCID of the node pool"
  value       = module.oke.node_pool_id
}

output "kubeconfig" {
  description = "Kubeconfig content for cluster access (use: terraform output -raw kubeconfig > ~/.kube/config)"
  value       = module.oke.kubeconfig
  sensitive   = true
}

# ============================================
# CONFIGURATION SUMMARY
# ============================================

output "configuration_summary" {
  description = "Summary of the deployment configuration"
  value = {
    region             = var.region
    vcn_cidr           = var.vcn_cidr
    cluster_type       = var.cluster_type
    kubernetes_version = var.kubernetes_version
    node_count         = var.node_count
    node_shape         = var.node_shape
    kubapi_is_public   = var.kubapi_subnet_is_public
    lb_is_public       = var.lb_subnet_is_public
  }
}