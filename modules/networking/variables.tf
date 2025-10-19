# ============================================
# NETWORKING MODULE VARIABLES - REFACTORED
# Simplified and focused on networking concerns
# ============================================

variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
}

variable "vcn_display_name" {
  description = "Display name for the VCN"
  type        = string
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN"
  type        = string
}

variable "nat_display_name" {
  description = "Display name for the NAT Gateway"
  type        = string
}

variable "svc_display_name" {
  description = "Display name for the Service Gateway"
  type        = string
}

variable "igw_display_name" {
  description = "Display name for the Internet Gateway"
  type        = string
}

variable "kubapi_subnet_is_public" {
  description = "Whether Kubernetes API subnet should be public"
  type        = bool
}

variable "lb_subnet_is_public" {
  description = "Whether Load Balancer subnet should be public"
  type        = bool
}