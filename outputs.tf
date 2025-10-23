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

# ============================================
# BASTION OUTPUTS
# Add these to your existing outputs.tf
# ============================================

# ============================================
# BASTION OUTPUTS
# ============================================

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].bastion_public_ip : null
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = var.enable_bastion ? "ssh -i <private_key_file> opc@${module.bastion[0].bastion_public_ip}" : null
}

output "bastion_tunnel_command" {
  description = "SSH tunnel command for kubectl access through bastion"
  value = var.enable_bastion && !var.kubapi_subnet_is_public ? format(
    "ssh -i <private_key_file> -L 6443:%s:6443 opc@%s",
    split("//", split(":", module.oke.cluster_endpoint)[1])[1],
    module.bastion[0].bastion_public_ip
  ) : null
}

output "bastion_connection_details" {
  description = "Complete bastion connection information"
  value = var.enable_bastion ? {
    public_ip        = module.bastion[0].bastion_public_ip
    private_ip       = module.bastion[0].bastion_private_ip
    ssh_command      = "ssh -i <private_key_file> opc@${module.bastion[0].bastion_public_ip}"
    sample_app_path  = "/home/opc/customer-management-app"
    tools_installed  = ["docker", "kubectl", "oci-cli", "helm", "k9s", "stern"]
    check_setup_log  = "ssh opc@${module.bastion[0].bastion_public_ip} 'sudo tail -f /var/log/bastion-setup.log'"
  } : null
  sensitive = false
}

# ============================================
# WORKSHOP ACCESS INFORMATION
# ============================================

output "workshop_access_info" {
  description = "Complete workshop access information"
  value = var.enable_bastion ? {
    step1_connect_bastion = "ssh -i <private_key_file> opc@${module.bastion[0].bastion_public_ip}"
    step2_check_cluster   = "kubectl get nodes"
    step3_deploy_app = {
      setup_registry = "cd ~/customer-management-app && ./scripts/k8s/01-setup-registry.sh"
      build_images   = "./scripts/k8s/02-build-and-push.sh"
      deploy_k8s     = "./scripts/k8s/03-deploy-all.sh"
      get_access     = "./scripts/k8s/05-get-access-info.sh"
    }
    step4_access_app = "Check LoadBalancer external IP from step3 output"
    helpful_commands = {
      k9s            = "Interactive Kubernetes UI"
      stern          = "Multi-pod log viewer"
      oci_login      = "oci-registry-login.sh"
      cluster_info   = "cluster-info.sh"
    }
  } : null
}

# ============================================
# COMPLETE DEPLOYMENT SUMMARY
# ============================================

output "deployment_summary" {
  description = "Complete deployment summary with all access points"
  value = {
    region             = var.region
    vcn_cidr           = var.vcn_cidr
    cluster_name       = module.oke.cluster_name
    kubernetes_version = var.kubernetes_version
    cluster_endpoint   = module.oke.cluster_endpoint
    node_count         = var.node_count
    kubapi_is_public   = var.kubapi_subnet_is_public
    lb_is_public       = var.lb_subnet_is_public
    bastion = var.enable_bastion ? {
      enabled    = true
      public_ip  = module.bastion[0].bastion_public_ip
      subnet     = module.bastion[0].bastion_subnet_cidr
    } : {
      enabled = false
    }
    next_steps = var.enable_bastion ? [
      "SSH to bastion: ssh -i <key> opc@${module.bastion[0].bastion_public_ip}",
      "Deploy sample app: Follow instructions in ~/customer-management-app/KUBERNETES.md",
      "Or run automated scripts in ~/customer-management-app/scripts/k8s/"
    ] : [
      "Configure kubectl with: terraform output -raw kubeconfig > ~/.kube/config",
      "Deploy applications using kubectl"
    ]
  }
}
