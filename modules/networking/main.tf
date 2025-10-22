# ============================================
# NETWORKING MODULE MAIN - WITH AUTO PUBLIC KUBEAPI ACCESS
# ============================================

# ============================================
# LOCALS - Configuration
# ============================================

locals {
  # Subnet definitions
  subnets = {
    kubapi = {
      cidr_block                 = cidrsubnet(var.vcn_cidr, 13, 0)  # 10.0.0.0/29
      display_name               = var.kubapi_subnet_is_public ? "sn-okedev-kubapi-pub" : "sn-okedev-kubapi-priv"
      dns_label                  = "kubapi"
      prohibit_public_ip_on_vnic = !var.kubapi_subnet_is_public
      is_public                  = var.kubapi_subnet_is_public
    }
    workernode = {
      cidr_block                 = cidrsubnet(var.vcn_cidr, 8, 1)   # 10.0.1.0/24
      display_name               = "sn-okedev-workernode-priv"
      dns_label                  = "worker"
      prohibit_public_ip_on_vnic = true
      is_public                  = false
    }
    pod = {
      cidr_block                 = cidrsubnet(var.vcn_cidr, 3, 1)   # 10.0.32.0/19
      display_name               = "sn-okedev-pod-priv"
      dns_label                  = "pod"
      prohibit_public_ip_on_vnic = true
      is_public                  = false
    }
    lb = {
      cidr_block                 = cidrsubnet(var.vcn_cidr, 8, 2)   # 10.0.2.0/24
      display_name               = var.lb_subnet_is_public ? "sn-okedev-lb-pub" : "sn-okedev-lb-priv"
      dns_label                  = "lb"
      prohibit_public_ip_on_vnic = !var.lb_subnet_is_public
      is_public                  = var.lb_subnet_is_public
    }
  }

  # Route table definitions
  route_tables = {
    kubapi = {
      display_name = var.kubapi_subnet_is_public ? "rt-okedev-kubapi-pub" : "rt-okedev-kubapi-priv"
      is_public    = var.kubapi_subnet_is_public
    }
    workernode = {
      display_name = "rt-okedev-workernode-priv"
      is_public    = false
    }
    pod = {
      display_name = "rt-okedev-pod-priv"
      is_public    = false
    }
    lb = {
      display_name = var.lb_subnet_is_public ? "rt-okedev-lb-pub" : "rt-okedev-lb-priv"
      is_public    = var.lb_subnet_is_public
    }
  }

  # Route rules for private subnets (NAT + Service Gateway)
  private_route_rules = [
    {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_nat_gateway.nat.id
      description       = "Default route to NAT Gateway"
    },
    {
      destination       = data.oci_core_services.all_services.services[0].cidr_block
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = oci_core_service_gateway.svc.id
      description       = "Route to OCI Services"
    }
  ]

  # Route rules for public subnets (Internet Gateway only)
  public_route_rules = [
    {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_internet_gateway.igw.id
      description       = "Default route to Internet Gateway"
    }
  ]

  # Base ingress rules for KubeAPI (always included)
  kubapi_base_ingress = [
    { stateless = false, source = "10.0.1.0/24", source_type = "CIDR_BLOCK", protocol = "6", description = "Worker to API (6443)", tcp_options = { min = 6443, max = 6443 } },
    { stateless = false, source = "10.0.1.0/24", source_type = "CIDR_BLOCK", protocol = "6", description = "Worker to API (12250)", tcp_options = { min = 12250, max = 12250 } },
    { stateless = false, source = "10.0.32.0/19", source_type = "CIDR_BLOCK", protocol = "6", description = "Pod to API (6443)", tcp_options = { min = 6443, max = 6443 } },
    { stateless = false, source = "10.0.32.0/19", source_type = "CIDR_BLOCK", protocol = "6", description = "Pod to API (12250)", tcp_options = { min = 12250, max = 12250 } },
    { stateless = false, source = "10.0.1.0/24", source_type = "CIDR_BLOCK", protocol = "1", description = "Path Discovery", icmp_options = { type = 3, code = 4 } }
  ]

  # Public internet access rule (only when kubapi is public)
  kubapi_public_ingress = var.kubapi_subnet_is_public ? [
    { stateless = false, source = "0.0.0.0/0", source_type = "CIDR_BLOCK", protocol = "6", description = "Public internet to Kubernetes API (6443)", tcp_options = { min = 6443, max = 6443 } }
  ] : []

  # Combined KubeAPI ingress rules
  kubapi_ingress = concat(local.kubapi_base_ingress, local.kubapi_public_ingress)

  # Security list definitions
  security_lists = {
    sl_kubapi = {
      display_name = "sl-okedev-kubapi"
      ingress      = local.kubapi_ingress
      egress = [
        { stateless = false, destination = "OCI_SERVICES", destination_type = "SERVICE_CIDR_BLOCK", protocol = "6", description = "API to OKE (443)", tcp_options = { min = 443, max = 443 } },
        { stateless = false, destination = "10.0.32.0/19", destination_type = "CIDR_BLOCK", protocol = "all", description = "API to Pods" },
        { stateless = false, destination = "10.0.1.0/24", destination_type = "CIDR_BLOCK", protocol = "1", description = "Path Discovery", icmp_options = { type = 3, code = 4 } },
        { stateless = false, destination = "10.0.1.0/24", destination_type = "CIDR_BLOCK", protocol = "6", description = "API to Worker (10250)", tcp_options = { min = 10250, max = 10250 } }
      ]
    }
    sl_workernode = {
      display_name = "sl-okedev-workernode"
      ingress = [
        { stateless = false, source = "10.0.1.0/24", source_type = "CIDR_BLOCK", protocol = "all", description = "Worker to Worker" },
        { stateless = false, source = "10.0.32.0/19", source_type = "CIDR_BLOCK", protocol = "all", description = "Pod to Worker" },
        { stateless = false, source = "10.0.0.0/29", source_type = "CIDR_BLOCK", protocol = "6", description = "API to Worker (all)" },
        { stateless = false, source = "0.0.0.0/0", source_type = "CIDR_BLOCK", protocol = "1", description = "Path Discovery", icmp_options = { type = 3, code = 4 } },
        { stateless = false, source = "10.0.0.0/29", source_type = "CIDR_BLOCK", protocol = "6", description = "API to Worker (10250)", tcp_options = { min = 10250, max = 10250 } },
        { stateless = false, source = "0.0.0.0/0", source_type = "CIDR_BLOCK", protocol = "6", description = "SSH to Worker", tcp_options = { min = 22, max = 22 } },
        { stateless = false, source = "10.0.2.0/24", source_type = "CIDR_BLOCK", protocol = "all", description = "LB to Worker" }
      ]
      egress = [
        { stateless = false, destination = "10.0.1.0/24", destination_type = "CIDR_BLOCK", protocol = "all", description = "Worker to Worker" },
        { stateless = false, destination = "10.0.32.0/19", destination_type = "CIDR_BLOCK", protocol = "all", description = "Worker to Pod" },
        { stateless = false, destination = "0.0.0.0/0", destination_type = "CIDR_BLOCK", protocol = "1", description = "Path Discovery", icmp_options = { type = 3, code = 4 } },
        { stateless = false, destination = "OCI_SERVICES", destination_type = "SERVICE_CIDR_BLOCK", protocol = "6", description = "Worker to OKE" },
        { stateless = false, destination = "10.0.0.0/29", destination_type = "CIDR_BLOCK", protocol = "6", description = "Worker to API (6443)", tcp_options = { min = 6443, max = 6443 } },
        { stateless = false, destination = "10.0.0.0/29", destination_type = "CIDR_BLOCK", protocol = "6", description = "Worker to API (12250)", tcp_options = { min = 12250, max = 12250 } }
      ]
    }
    sl_pod = {
      display_name = "sl-okedev-pod"
      ingress = [
        { stateless = false, source = "10.0.0.0/29", source_type = "CIDR_BLOCK", protocol = "all", description = "API to Pod" },
        { stateless = false, source = "10.0.1.0/24", source_type = "CIDR_BLOCK", protocol = "all", description = "Worker to Pod" },
        { stateless = false, source = "10.0.32.0/19", source_type = "CIDR_BLOCK", protocol = "all", description = "Pod to Pod" }
      ]
      egress = [
        { stateless = false, destination = "10.0.32.0/19", destination_type = "CIDR_BLOCK", protocol = "all", description = "Pod to Pod" },
        { stateless = false, destination = "OCI_SERVICES", destination_type = "SERVICE_CIDR_BLOCK", protocol = "1", description = "Path Discovery", icmp_options = { type = 3, code = 4 } },
        { stateless = false, destination = "OCI_SERVICES", destination_type = "SERVICE_CIDR_BLOCK", protocol = "6", description = "Pod to OCI Services" },
        { stateless = false, destination = "10.0.0.0/29", destination_type = "CIDR_BLOCK", protocol = "6", description = "Pod to API (6443)", tcp_options = { min = 6443, max = 6443 } },
        { stateless = false, destination = "10.0.0.0/29", destination_type = "CIDR_BLOCK", protocol = "6", description = "Pod to API (12250)", tcp_options = { min = 12250, max = 12250 } }
      ]
    }
    sl_lb = {
      display_name = "sl-okedev-lb"
      ingress = [
        { stateless = false, source = "0.0.0.0/0", source_type = "CIDR_BLOCK", protocol = "6", description = "Internet to LB (443)", tcp_options = { min = 443, max = 443 } }
      ]
      egress = [
        { stateless = false, destination = "10.0.1.0/24", destination_type = "CIDR_BLOCK", protocol = "all", description = "LB to Worker" }
      ]
    }
  }

  # Resolve OCI_SERVICES placeholder to actual CIDR
  resolved_security_lists = {
    for sl_name, sl in local.security_lists : sl_name => {
      display_name = sl.display_name
      ingress      = sl.ingress
      egress = [
        for rule in sl.egress :
        rule.destination == "OCI_SERVICES" ?
        merge(rule, { destination = data.oci_core_services.all_services.services[0].cidr_block }) :
        rule
      ]
    }
  }
}

# ============================================
# VCN
# ============================================

resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = var.vcn_display_name
  dns_label      = var.vcn_dns_label
}

# ============================================
# GATEWAYS
# ============================================

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = var.igw_display_name
  enabled        = true
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = var.nat_display_name
}

resource "oci_core_service_gateway" "svc" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = var.svc_display_name

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

# ============================================
# ROUTE TABLES
# ============================================

resource "oci_core_route_table" "rt" {
  for_each = local.route_tables

  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = each.value.display_name

  dynamic "route_rules" {
    for_each = each.value.is_public ? local.public_route_rules : local.private_route_rules
    content {
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity_id
      description       = route_rules.value.description
    }
  }
}

# ============================================
# SECURITY LISTS
# ============================================

resource "oci_core_security_list" "sl" {
  for_each = local.resolved_security_lists

  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = each.value.display_name

  dynamic "ingress_security_rules" {
    for_each = each.value.ingress
    content {
      stateless   = ingress_security_rules.value.stateless
      source      = ingress_security_rules.value.source
      source_type = ingress_security_rules.value.source_type
      protocol    = ingress_security_rules.value.protocol
      description = ingress_security_rules.value.description

      dynamic "tcp_options" {
        for_each = lookup(ingress_security_rules.value, "tcp_options", null) != null ? [ingress_security_rules.value.tcp_options] : []
        content {
          min = tcp_options.value.min
          max = tcp_options.value.max
        }
      }

      dynamic "icmp_options" {
        for_each = lookup(ingress_security_rules.value, "icmp_options", null) != null ? [ingress_security_rules.value.icmp_options] : []
        content {
          type = icmp_options.value.type
          code = icmp_options.value.code
        }
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.egress
    content {
      stateless        = egress_security_rules.value.stateless
      destination      = egress_security_rules.value.destination
      destination_type = egress_security_rules.value.destination_type
      protocol         = egress_security_rules.value.protocol
      description      = egress_security_rules.value.description

      dynamic "tcp_options" {
        for_each = lookup(egress_security_rules.value, "tcp_options", null) != null ? [egress_security_rules.value.tcp_options] : []
        content {
          min = tcp_options.value.min
          max = tcp_options.value.max
        }
      }

      dynamic "icmp_options" {
        for_each = lookup(egress_security_rules.value, "icmp_options", null) != null ? [egress_security_rules.value.icmp_options] : []
        content {
          type = icmp_options.value.type
          code = icmp_options.value.code
        }
      }
    }
  }
}

# ============================================
# SUBNETS
# ============================================

resource "oci_core_subnet" "subnets" {
  for_each = local.subnets

  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_virtual_network.vcn.id
  cidr_block                 = each.value.cidr_block
  display_name               = each.value.display_name
  dns_label                  = each.value.dns_label
  route_table_id             = oci_core_route_table.rt[each.key].id
  security_list_ids          = [oci_core_security_list.sl["sl_${each.key}"].id]
  prohibit_public_ip_on_vnic = each.value.prohibit_public_ip_on_vnic
}