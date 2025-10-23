# ============================================
# ROOT MAIN - WITH BASTION MODULE
# Orchestrates networking, OKE, and bastion modules
# ============================================

# ============================================
# NETWORKING MODULE
# Creates VCN, subnets, gateways, and routing
# ============================================

module "networking" {
  source = "./modules/networking"

  # Common
  compartment_id = var.compartment_id

  # VCN Configuration
  vcn_cidr         = var.vcn_cidr
  vcn_display_name = var.vcn_display_name
  vcn_dns_label    = var.vcn_dns_label

  # Gateway Configuration
  nat_display_name = var.nat_display_name
  svc_display_name = var.svc_display_name
  igw_display_name = var.igw_display_name

  # Public/Private Configuration
  kubapi_subnet_is_public = var.kubapi_subnet_is_public
  lb_subnet_is_public     = var.lb_subnet_is_public
}

# ============================================
# OKE MODULE
# Creates Kubernetes cluster and node pool
# ============================================

module "oke" {
  source = "./modules/oke"

  # Common
  compartment_id = var.compartment_id

  # Network Dependencies (from networking module)
  vcn_id           = module.networking.vcn_id
  kubapi_subnet_id = module.networking.subnet_ids["kubapi"]
  lb_subnet_id     = module.networking.subnet_ids["lb"]
  worker_subnet_id = module.networking.subnet_ids["workernode"]
  pod_subnet_id    = module.networking.subnet_ids["pod"]

  # Cluster Configuration
  cluster_name                    = var.cluster_name
  kubernetes_version              = var.kubernetes_version
  cluster_type                    = var.cluster_type
  cni_type                        = var.cni_type
  is_kubernetes_dashboard_enabled = var.is_kubernetes_dashboard_enabled
  is_public_ip_enabled            = var.kubapi_subnet_is_public

  # Node Pool Configuration
  node_pool_name                            = var.node_pool_name
  node_shape                                = var.node_shape
  node_count                                = var.node_count
  node_pool_node_shape_config_ocpus         = var.node_pool_node_shape_config_ocpus
  node_pool_node_shape_config_memory_in_gbs = var.node_pool_node_shape_config_memory_in_gbs
  boot_volume_size_in_gbs                   = var.boot_volume_size_in_gbs
  ssh_public_key                            = var.ssh_public_key
  max_pods_per_node                         = var.max_pods_per_node
  nsg_ids                                   = var.nsg_ids
  pod_nsg_ids                               = var.pod_nsg_ids
}

# ============================================
# BASTION MODULE
# Creates bastion host for cluster access
# ============================================

module "bastion" {
  source = "./modules/bastion"
  
  # Only create bastion if enabled
  count = var.enable_bastion ? 1 : 0

  # Common
  compartment_id = var.compartment_id
  region         = var.region

  # Network Configuration
  vcn_id              = module.networking.vcn_id
  vcn_cidr            = var.vcn_cidr
  internet_gateway_id = module.networking.internet_gateway_id
  service_gateway_id  = module.networking.service_gateway_id
  
  # Use service CIDR from networking module data source
  services_cidr = data.oci_core_services.all_services.services[0].cidr_block

  # Bastion Subnet Configuration
  create_bastion_subnet = var.create_bastion_subnet
  bastion_subnet_cidr   = var.bastion_subnet_cidr
  existing_subnet_id    = var.bastion_existing_subnet_id
  
  # Access Control
  allowed_ssh_cidr = var.bastion_allowed_ssh_cidr
  ssh_public_key   = var.ssh_public_key  # Same key as nodes
  ssh_private_key  = var.ssh_private_key  # Optional for provisioning
  
  # Instance Configuration
  bastion_display_name = var.bastion_display_name
  bastion_shape        = var.bastion_shape
  bastion_shape_config = var.bastion_shape_config
  boot_volume_size     = var.bastion_boot_volume_size
  
  # Tool Versions
  docker_version  = var.docker_version
  kubectl_version = var.kubectl_version
  oci_cli_version = var.oci_cli_version
  helm_version    = var.helm_version
  
  # OKE Integration
  cluster_id          = module.oke.cluster_id
  cluster_endpoint    = module.oke.cluster_endpoint
  setup_kubeconfig    = var.bastion_setup_kubeconfig
  tenancy_namespace   = var.tenancy_namespace
  
  # Provisioning Options
  wait_for_cloud_init = var.bastion_wait_for_cloud_init
  
  # Tags
  environment = var.environment
  tags        = var.tags
}

# ============================================
# DATA SOURCE FOR SERVICE CIDR
# (Required for bastion module)
# ============================================

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
