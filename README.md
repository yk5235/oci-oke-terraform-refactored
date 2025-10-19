# 🚀 OCI OKE Terraform - Refactored & Production-Ready

Terraform configuration for deploying Oracle Kubernetes Engine (OKE) clusters on Oracle Cloud Infrastructure with **configurable public/private networking**.

## ✨ Key Features

- ✅ **Configurable Public/Private Subnets** - Simple boolean flags for KubeAPI and LB
- ✅ **VCN-Native Pod Networking** - High performance with OCI_VCN_IP_NATIVE
- ✅ **Clean Modular Structure** - Well-organized and maintainable
- ✅ **Security Best Practices** - Based on OCI recommendations
- ✅ **Input Validation** - Prevents common configuration errors
- ✅ **Comprehensive Outputs** - Get all the information you need

## 🎯 Quick Start

### 1. Configure Your Deployment

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vi terraform.tfvars
```

**Minimum required configuration:**
```hcl
region         = "ap-singapore-1"
compartment_id = "ocid1.compartment.oc1..your-ocid"
ssh_public_key = "ssh-rsa AAAAB3..."

# Choose your configuration:
kubapi_subnet_is_public = false  # Private (access via bastion)
lb_subnet_is_public     = false  # Private (internal services only)
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

**Deployment time:** ~12-15 minutes

### 3. Access Your Cluster

```bash
# Get kubeconfig
terraform output -raw kubeconfig > ~/.kube/config

# If kubapi is private, set up tunnel via bastion
# If kubapi is public, use directly
kubectl get nodes
```

## 📊 Configuration Options

### Public vs Private Subnets

| Configuration | Use Case | Access Method |
|---------------|----------|---------------|
| **Both Private** (default) | Production, highest security | Bastion host or VPN |
| **KubeAPI Public** | Development, remote access | Direct kubectl access |
| **LB Public** | Public-facing applications | Internet → LB → Apps |
| **Both Public** | Quick testing | Direct access to everything |

### Simple Configuration Examples

#### Private Cluster (Production)
```hcl
kubapi_subnet_is_public = false
lb_subnet_is_public     = false
```

#### Public API, Private LB (Development)
```hcl
kubapi_subnet_is_public = true
lb_subnet_is_public     = false
```

#### Public LB, Private API (Public Apps)
```hcl
kubapi_subnet_is_public = false
lb_subnet_is_public     = true
```

#### All Public (Testing)
```hcl
kubapi_subnet_is_public = true
lb_subnet_is_public     = true
```

## 📁 Project Structure

```
.
├── main.tf                    # Root orchestration
├── variables.tf               # Root variables with validation
├── outputs.tf                 # Consolidated outputs
├── provider.tf                # OCI provider configuration
├── versions.tf                # Terraform version requirements
├── terraform.tfvars.example   # Configuration template
├── README.md                  # This file
│
└── modules/
    ├── networking/
    │   ├── main.tf            # Network resources
    │   ├── variables.tf       # Network inputs
    │   ├── outputs.tf         # Network outputs
    │   └── data.tf            # OCI services data
    │
    └── oke/
        ├── main.tf            # Cluster and node pool
        ├── variables.tf       # OKE inputs
        ├── outputs.tf         # OKE outputs
        └── data.tf            # Images and ADs
```

## 🏗️ What Gets Deployed

### Networking Resources
- **VCN** - Virtual Cloud Network (10.0.0.0/16)
- **Subnets** - 4 regional subnets:
  - KubeAPI: 10.0.0.0/29 (configurable public/private)
  - Workers: 10.0.1.0/24 (always private)
  - Pods: 10.0.32.0/19 (always private)
  - LB: 10.0.2.0/24 (configurable public/private)
- **Gateways**:
  - Internet Gateway (for public subnets)
  - NAT Gateway (for private subnet internet access)
  - Service Gateway (for OCI services)
- **Route Tables** - Dynamic routing based on subnet configuration
- **Security Lists** - OCI best practice security rules

### OKE Resources
- **OKE Cluster** - Enhanced cluster with VCN-native networking
- **Node Pool** - Managed worker nodes with flexible shapes
- **Configuration** - CNI, pod networking, and security

## 🔒 Security

### Default Security Posture
- All subnets **private by default**
- Worker nodes have no public IPs
- Pods use private IPs from dedicated subnet
- Internet access via NAT Gateway
- OCI service access via Service Gateway

### Security Lists
Based on OCI best practices for OKE with VCN-native pod networking:
- Minimum required ingress rules
- Egress rules for OCI services
- Path discovery (ICMP) rules
- SSH access to workers (optional)

## 🔧 Advanced Configuration

### Node Pool Customization

```hcl
node_shape    = "VM.Standard.E4.Flex"
node_count    = 3
node_pool_node_shape_config_ocpus         = 4
node_pool_node_shape_config_memory_in_gbs = 32
boot_volume_size_in_gbs                   = 100
```

### Network Customization

```hcl
vcn_cidr         = "172.16.0.0/16"
vcn_display_name = "my-custom-vcn"
vcn_dns_label    = "mycluster"
```

### Cluster Options

```hcl
kubernetes_version                 = "v1.33.1"
cluster_type                       = "ENHANCED_CLUSTER"
cni_type                           = "OCI_VCN_IP_NATIVE"
is_kubernetes_dashboard_enabled    = true
```

## 📊 Outputs

After deployment, you'll get:

```bash
# View all outputs
terraform output

# Get kubeconfig
terraform output -raw kubeconfig > ~/.kube/config

# Get cluster endpoint
terraform output cluster_endpoint

# View configuration summary
terraform output configuration_summary
```

## 🎯 Accessing the Cluster

### Private KubeAPI (Default)

Access via bastion host:

```bash
# 1. Create bastion session in OCI Console
# 2. Set up SSH tunnel
ssh -i key.pem -N -L 6443:<api-private-ip>:6443 -p 22 \
  ocid1.bastionsession...@host.bastion.region.oci.oraclecloud.com

# 3. Update kubeconfig server to localhost
# Change: https://10.0.0.x:6443
# To:     https://127.0.0.1:6443

# 4. Use kubectl
kubectl get nodes
```

### Public KubeAPI

Direct access:

```bash
# Get kubeconfig
terraform output -raw kubeconfig > ~/.kube/config

# Use kubectl directly
kubectl get nodes
```

## 🧹 Cleanup

```bash
terraform destroy
```

**Destruction time:** ~5-10 minutes

## 🔍 Troubleshooting

### Pod Network Configuration Timeout

If you see this error, check:
1. Security lists allow traffic between workers, pods, and API
2. Service Gateway is configured for your region
3. Route tables have correct Service Gateway routes

### Cannot Access Cluster

**Private KubeAPI:**
- Ensure bastion tunnel is active
- Verify kubeconfig points to 127.0.0.1:6443

**Public KubeAPI:**
- Check security list allows your IP
- Verify kubeconfig has correct public endpoint

## 📝 Best Practices

### Security
- ✅ Use private subnets for production
- ✅ Implement Network Security Groups (NSGs) for fine-grained control
- ✅ Rotate SSH keys regularly
- ✅ Use bastion for administrative access
- ✅ Enable audit logging

### Operations
- ✅ Use remote state (OCI Object Storage)
- ✅ Implement state locking
- ✅ Use workspaces for multi-environment
- ✅ Tag all resources appropriately
- ✅ Monitor cluster and node metrics

### Cost Optimization
- ✅ Use appropriate node shapes
- ✅ Implement cluster autoscaling
- ✅ Use spot instances for non-critical workloads
- ✅ Clean up unused load balancers
- ✅ Review and right-size regularly

## 🚀 What's New in This Refactor

### Improvements Over Original
1. **Simplified Configuration** - Just 2 boolean flags for public/private
2. **Better Organization** - Clear separation of concerns
3. **Input Validation** - Catch errors before apply
4. **Comprehensive Outputs** - All the info you need
5. **Clean Code** - Removed duplicates and complexity
6. **Better Documentation** - Clear examples and explanations

### Breaking Changes
- Removed complex `subnets` variable override
- Simplified to `kubapi_subnet_is_public` and `lb_subnet_is_public`
- Updated module structure and naming

### Migration from Old Version
```bash
# 1. Backup current state
cp terraform.tfstate terraform.tfstate.backup

# 2. Update configuration files
# Replace old files with refactored versions

# 3. Update terraform.tfvars
# Change from complex subnet definitions to simple boolean flags
kubapi_subnet_is_public = false
lb_subnet_is_public     = false

# 4. Review plan carefully
terraform plan

# 5. Apply if changes look correct
terraform apply
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly
4. Submit a pull request

## 📄 License

MIT License - use freely for your projects

## 🙏 Acknowledgments

- Based on OCI best practices for OKE
- VCN-native pod networking architecture
- Security list configurations from OCI documentation

---

**Questions?** Open an issue on GitHub
**Feedback?** PRs welcome!