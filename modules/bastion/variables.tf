# ============================================
# BASTION MODULE VARIABLES
# ============================================

# ============================================
# REQUIRED VARIABLES
# ============================================

variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR block of the VCN"
  type        = string
}

variable "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for accessing the bastion host"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
}

# ============================================
# OPTIONAL - NETWORKING
# ============================================

variable "create_bastion_subnet" {
  description = "Create a dedicated subnet for bastion host"
  type        = bool
  default     = true
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for bastion subnet (required if create_bastion_subnet is true)"
  type        = string
  default     = "10.0.3.0/28"  # 16 IPs
}

variable "existing_subnet_id" {
  description = "Existing subnet ID to use if not creating new subnet"
  type        = string
  default     = ""
}

variable "service_gateway_id" {
  description = "OCID of the Service Gateway (optional)"
  type        = string
  default     = ""
}

variable "services_cidr" {
  description = "CIDR block for OCI services"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to bastion"
  type        = string
  default     = "0.0.0.0/0"
  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "Must be a valid CIDR block"
  }
}

variable "nsg_ids" {
  description = "List of Network Security Group OCIDs to attach to bastion"
  type        = list(string)
  default     = []
}

# ============================================
# INSTANCE CONFIGURATION
# ============================================

variable "bastion_display_name" {
  description = "Display name for the bastion host"
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

variable "boot_volume_size" {
  description = "Size of boot volume in GBs"
  type        = number
  default     = 50
  validation {
    condition     = var.boot_volume_size >= 50
    error_message = "Boot volume must be at least 50 GB"
  }
}

# ============================================
# TOOL VERSIONS
# ============================================

variable "docker_version" {
  description = "Docker version to install (use 'latest' for latest)"
  type        = string
  default     = "latest"
}

variable "kubectl_version" {
  description = "Kubectl version to install (use 'latest' for latest stable)"
  type        = string
  default     = "latest"
}

variable "oci_cli_version" {
  description = "OCI CLI version to install"
  type        = string
  default     = "latest"
}

variable "helm_version" {
  description = "Helm version to install"
  type        = string
  default     = "latest"
}

# ============================================
# OKE INTEGRATION
# ============================================

variable "cluster_id" {
  description = "OCID of the OKE cluster (for kubeconfig setup)"
  type        = string
  default     = ""
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  type        = string
  default     = ""
}

variable "setup_kubeconfig" {
  description = "Automatically setup kubeconfig for the OKE cluster"
  type        = bool
  default     = true
}

variable "tenancy_namespace" {
  description = "Tenancy namespace for OCI Container Registry"
  type        = string
  default     = ""
}

# ============================================
# PROVISIONING OPTIONS
# ============================================

variable "ssh_private_key" {
  description = "SSH private key content for remote provisioning (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "wait_for_cloud_init" {
  description = "Wait for cloud-init to complete before marking resource as created"
  type        = bool
  default     = false
}

# ============================================
# TAGGING
# ============================================

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Freeform tags to apply to resources"
  type        = map(string)
  default     = {}
}
