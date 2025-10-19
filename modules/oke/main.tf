# ============================================
# OKE MODULE MAIN - REFACTORED
# Clean and well-documented
# ============================================

# ============================================
# OKE CLUSTER
# ============================================

resource "oci_containerengine_cluster" "cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = var.vcn_id
  type               = var.cluster_type

  cluster_pod_network_options {
    cni_type = var.cni_type
  }

  endpoint_config {
    is_public_ip_enabled = var.is_public_ip_enabled
    subnet_id            = var.kubapi_subnet_id
  }

  options {
    service_lb_subnet_ids = [var.lb_subnet_id]

    add_ons {
      is_kubernetes_dashboard_enabled = var.is_kubernetes_dashboard_enabled
    }
  }
}

# ============================================
# NODE POOL
# ============================================

resource "oci_containerengine_node_pool" "node_pool" {
  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = var.compartment_id
  name               = var.node_pool_name
  kubernetes_version = var.kubernetes_version
  node_shape         = var.node_shape

  node_source_details {
    image_id                = data.oci_core_images.node_images.images[0].id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = var.worker_subnet_id
    }

    size = var.node_count

    nsg_ids = var.nsg_ids

    node_pool_pod_network_option_details {
      cni_type          = var.cni_type
      max_pods_per_node = var.max_pods_per_node
      pod_nsg_ids       = var.pod_nsg_ids
      pod_subnet_ids    = [var.pod_subnet_id]
    }
  }

  node_shape_config {
    memory_in_gbs = var.node_pool_node_shape_config_memory_in_gbs
    ocpus         = var.node_pool_node_shape_config_ocpus
  }

  ssh_public_key = var.ssh_public_key
}