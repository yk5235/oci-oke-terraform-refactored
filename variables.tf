# ============================================
# ROOT VARIABLES - REFACTORED
# Clean, organized, and well-documented
# ============================================

# ============================================
# PROVIDER CONFIGURATION
# ============================================

variable "region" {
  description = "OCI region where resources will be created"
  type        = string
  default     = "us-ashburn-1"
}

# ============================================
# COMMON VARIABLES
# ============================================

variable "compartment_id" {
  description = "OCID of the compartment where resources will be created"
  type        = string
  validation {
    condition     = can(regex("^ocid1\\.compartment\\.oc1\\.", var.compartment_id))
    error_message = "compartment_id must be a valid OCI compartment OCID."
  }
}

# ============================================
# NETWORKING VARIABLES
# ============================================

variable "vcn_cidr" {
  description = "CIDR block for the Virtual Cloud Network"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0))
    error_message = "vcn_cidr must be a valid CIDR block."
  }
}

variable "vcn_display_name" {
  description = "Display name for the VCN"
  type        = string
  default     = "vcn-okedev"
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN"
  type        = string
  default     = "okedev"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.vcn_dns_label))
    error_message = "DNS label must start with a letter and contain only lowercase letters and numbers (max 15 characters)."
  }
}

variable "nat_display_name" {
  description = "Display name for the NAT Gateway"
  type        = string
  default     = "ng-okedev"
}

variable "svc_display_name" {
  description = "Display name for the Service Gateway"
  type        = string
  default     = "sg-okedev"
}

variable "igw_display_name" {
  description = "Display name for the Internet Gateway"
  type        = string
  default     = "ig-okedev"
}

# ============================================
# SUBNET CONFIGURATION
# NEW: Simple boolean flags for public/private
# ============================================

variable "kubapi_subnet_is_public" {
  description = "Set to true to make Kubernetes API endpoint subnet public, false for private"
  type        = bool
  default     = false
}

variable "lb_subnet_is_public" {
  description = "Set to true to make Load Balancer subnet public, false for private"
  type        = bool
  default     = false
}

# ============================================
# OKE CLUSTER VARIABLES
# ============================================

variable "cluster_name" {
  description = "Name of the OKE cluster"
  type        = string
  default     = "oke-cluster-dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster and node pool"
  type        = string
  default     = "v1.32.1"
}

variable "cluster_type" {
  description = "Type of OKE cluster (BASIC_CLUSTER or ENHANCED_CLUSTER)"
  type        = string
  default     = "ENHANCED_CLUSTER"
  validation {
    condition     = contains(["BASIC_CLUSTER", "ENHANCED_CLUSTER"], var.cluster_type)
    error_message = "cluster_type must be either BASIC_CLUSTER or ENHANCED_CLUSTER."
  }
}

variable "cni_type" {
  description = "CNI type for pod networking (OCI_VCN_IP_NATIVE or FLANNEL_OVERLAY)"
  type        = string
  default     = "OCI_VCN_IP_NATIVE"
  validation {
    condition     = contains(["OCI_VCN_IP_NATIVE", "FLANNEL_OVERLAY"], var.cni_type)
    error_message = "cni_type must be either OCI_VCN_IP_NATIVE or FLANNEL_OVERLAY."
  }
}

variable "is_kubernetes_dashboard_enabled" {
  description = "Whether to enable the Kubernetes Dashboard"
  type        = bool
  default     = false
}

# ============================================
# NODE POOL VARIABLES
# ============================================

variable "node_pool_name" {
  description = "Name of the worker node pool"
  type        = string
  default     = "oke-node-pool-dev"
}

variable "node_shape" {
  description = "Shape of the worker nodes (e.g., VM.Standard.E4.Flex)"
  type        = string
  default     = "VM.Standard.E3.Flex"
}

variable "node_count" {
  description = "Number of worker nodes in the node pool"
  type        = number
  default     = 2
  validation {
    condition     = var.node_count > 0 && var.node_count <= 1000
    error_message = "node_count must be between 1 and 1000."
  }
}

variable "node_pool_node_shape_config_ocpus" {
  description = "Number of OCPUs for flex worker nodes"
  type        = number
  default     = 2
  validation {
    condition     = var.node_pool_node_shape_config_ocpus >= 1
    error_message = "OCPUs must be at least 1."
  }
}

variable "node_pool_node_shape_config_memory_in_gbs" {
  description = "Memory in GBs for flex worker nodes"
  type        = number
  default     = 16
  validation {
    condition     = var.node_pool_node_shape_config_memory_in_gbs >= 1
    error_message = "Memory must be at least 1 GB."
  }
}

variable "boot_volume_size_in_gbs" {
  description = "Size of the boot volume for worker nodes in GB"
  type        = number
  default     = 50
  validation {
    condition     = var.boot_volume_size_in_gbs >= 50
    error_message = "Boot volume size must be at least 50 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for accessing worker nodes"
  type        = string
  validation {
    condition     = can(regex("^ssh-rsa |^ssh-ed25519 |^ecdsa-", var.ssh_public_key))
    error_message = "ssh_public_key must be a valid SSH public key."
  }
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node (null uses OKE defaults based on shape)"
  type        = number
  default     = null
}

variable "nsg_ids" {
  description = "List of Network Security Group OCIDs for cluster endpoint and worker nodes"
  type        = list(string)
  default     = []
}

variable "pod_nsg_ids" {
  description = "List of Network Security Group OCIDs for pods"
  type        = list(string)
  default     = []
}

# ============================================
# BASTION MODULE VARIABLES
# Add these to your existing variables.tf
# ============================================

# ============================================
# BASTION CONFIGURATION
# ============================================

variable "enable_bastion" {
  description = "Enable bastion host deployment"
  type        = bool
  default     = true
}

variable "create_bastion_subnet" {
  description = "Create a dedicated subnet for bastion host"
  type        = bool
  default     = true
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for bastion subnet"
  type        = string
  default     = "10.0.3.0/28"  # 16 IPs
  validation {
    condition     = can(cidrhost(var.bastion_subnet_cidr, 0))
    error_message = "bastion_subnet_cidr must be a valid CIDR block"
  }
}

variable "bastion_existing_subnet_id" {
  description = "Existing subnet ID for bastion (if not creating new subnet)"
  type        = string
  default     = ""
}

variable "bastion_allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to bastion (0.0.0.0/0 for anywhere)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "bastion_display_name" {
  description = "Display name for bastion host"
  type        = string
  default     = "oke-workshop-bastion"
}

variable "bastion_shape" {
  description = "Shape of the bastion instance"
  type        = string
  default     = "VM.Standard.E3.Flex"
}

variable "bastion_shape_config" {
  description = "Shape configuration for flexible shapes"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 1
    memory_in_gbs = 8
  }
}

variable "bastion_boot_volume_size" {
  description = "Boot volume size for bastion in GBs"
  type        = number
  default     = 50
}

# ============================================
# TOOL VERSIONS
# ============================================

variable "docker_version" {
  description = "Docker version to install on bastion"
  type        = string
  default     = "latest"
}

variable "kubectl_version" {
  description = "Kubectl version to install on bastion"
  type        = string
  default     = "latest"
}

variable "oci_cli_version" {
  description = "OCI CLI version to install on bastion"
  type        = string
  default     = "latest"
}

variable "helm_version" {
  description = "Helm version to install on bastion"
  type        = string
  default     = "latest"
}

# ============================================
# INTEGRATION OPTIONS
# ============================================

variable "bastion_setup_kubeconfig" {
  description = "Automatically setup kubeconfig on bastion"
  type        = bool
  default     = true
}

variable "bastion_wait_for_cloud_init" {
  description = "Wait for cloud-init to complete on bastion"
  type        = bool
  default     = false
}

variable "tenancy_namespace" {
  description = "Tenancy namespace for OCI Container Registry"
  type        = string
  default     = ""
}

# ============================================
# SSH KEYS (for provisioning)
# ============================================

variable "ssh_private_key" {
  description = "SSH private key for remote provisioning (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

# ============================================
# ENVIRONMENT & TAGS
# ============================================

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod"
  }
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "OKE-Workshop"
  }
}
