# ============================================
# OKE MODULE OUTPUTS - REFACTORED
# ============================================

output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = oci_containerengine_cluster.cluster.id
}

output "cluster_name" {
  description = "Name of the OKE cluster"
  value       = oci_containerengine_cluster.cluster.name
}

output "cluster_kubernetes_version" {
  description = "Kubernetes version of the cluster"
  value       = oci_containerengine_cluster.cluster.kubernetes_version
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = oci_containerengine_cluster.cluster.endpoints[0].kubernetes
}

output "node_pool_id" {
  description = "OCID of the node pool"
  value       = oci_containerengine_node_pool.node_pool.id
}

output "node_pool_name" {
  description = "Name of the node pool"
  value       = oci_containerengine_node_pool.node_pool.name
}

output "node_pool_kubernetes_version" {
  description = "Kubernetes version of the node pool"
  value       = oci_containerengine_node_pool.node_pool.kubernetes_version
}

output "kubeconfig" {
  description = "Kubeconfig content for cluster access"
  value       = data.oci_containerengine_cluster_kube_config.kube_config.content
  sensitive   = true
}