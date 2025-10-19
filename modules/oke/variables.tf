# ============================================
# OKE MODULE VARIABLES - REFACTORED
# ============================================

# ============================================
# COMMON
# ============================================

variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

# ============================================
# NETWORK DEPENDENCIES
# ============================================

variable "vcn_id" {
  description = "OCID of the VCN"
  type        = string
}

variable "kubapi_subnet_id" {
  description = "OCID of the Kubernetes API endpoint subnet"
  type        = string
}

variable "lb_subnet_id" {
  description = "OCID of the Load Balancer subnet"
  type        = string
}

variable "worker_subnet_id" {
  description = "OCID of the worker nodes subnet"
  type        = string
}

variable "pod_subnet_id" {
  description = "OCID of the pod subnet"
  type        = string
}

# ============================================
# CLUSTER CONFIGURATION
# ============================================

variable "cluster_name" {
  description = "Name of the OKE cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
}

variable "cluster_type" {
  description = "Type of OKE cluster"
  type        = string
}

variable "cni_type" {
  description = "CNI type for pod networking"
  type        = string
}

variable "is_public_ip_enabled" {
  description = "Whether the Kubernetes API endpoint has a public IP"
  type        = bool
}

variable "is_kubernetes_dashboard_enabled" {
  description = "Whether to enable the Kubernetes Dashboard"
  type        = bool
}

# ============================================
# NODE POOL CONFIGURATION
# ============================================

variable "node_pool_name" {
  description = "Name of the worker node pool"
  type        = string
}

variable "node_shape" {
  description = "Shape of the worker nodes"
  type        = string
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "node_pool_node_shape_config_ocpus" {
  description = "Number of OCPUs for worker nodes"
  type        = number
}

variable "node_pool_node_shape_config_memory_in_gbs" {
  description = "Memory in GBs for worker nodes"
  type        = number
}

variable "boot_volume_size_in_gbs" {
  description = "Size of the boot volume for worker nodes in GB"
  type        = number
}

variable "ssh_public_key" {
  description = "SSH public key for accessing worker nodes"
  type        = string
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node"
  type        = number
}

variable "nsg_ids" {
  description = "List of Network Security Group OCIDs"
  type        = list(string)
}

variable "pod_nsg_ids" {
  description = "List of Network Security Group OCIDs for pods"
  type        = list(string)
}