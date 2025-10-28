# ============================================
# BASTION MODULE - Main Configuration
# Complete implementation for OKE workshop bastion
# ============================================

# ============================================
# DATA SOURCES
# ============================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Get latest Oracle Linux 8 image
data "oci_core_images" "bastion_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.bastion_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ============================================
# BASTION SUBNET (Optional - dedicated subnet)
# ============================================

resource "oci_core_subnet" "bastion_subnet" {
  count = var.create_bastion_subnet ? 1 : 0

  compartment_id             = var.compartment_id
  vcn_id                     = var.vcn_id
  cidr_block                 = var.bastion_subnet_cidr
  display_name               = "sn-bastion-public"
  dns_label                  = "bastion"
  route_table_id             = oci_core_route_table.bastion_rt[0].id
  security_list_ids          = [oci_core_security_list.bastion_sl.id]
  prohibit_public_ip_on_vnic = false
}

# ============================================
# ROUTE TABLE FOR BASTION SUBNET
# ============================================

# Find the route table resource and replace it with:
resource "oci_core_route_table" "bastion_rt" {
  count = var.create_bastion_subnet ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "rt-bastion-public"

  # Only Internet Gateway route for public subnet
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.internet_gateway_id
    description       = "Default route to Internet Gateway"
  }
}

# ============================================
# SECURITY LIST FOR BASTION
# ============================================

resource "oci_core_security_list" "bastion_sl" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "sl-bastion"

  # Ingress Rules
  ingress_security_rules {
    stateless   = false
    source      = var.allowed_ssh_cidr
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    description = "SSH access to bastion from allowed CIDR"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow return traffic from VCN
  ingress_security_rules {
    stateless   = false
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    protocol    = "all"
    description = "Allow all traffic from VCN"
  }

  # Egress Rules
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    description      = "Allow all outbound traffic for internet access"
  }

  # Allow access to VCN
  egress_security_rules {
    stateless        = false
    destination      = var.vcn_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    description      = "Allow all traffic to VCN"
  }
}

# ============================================
# CLOUD-INIT SCRIPT
# ============================================

locals {
  # Use a simple bash script instead of complex cloud-init YAML
  cloud_init_script = <<-EOT
#!/bin/bash
exec > >(tee -a /var/log/bastion-setup.log)
exec 2>&1

echo "Starting bastion setup at $(date)"

#--------------------------------------------------------------------------------
# Install Core Tools (Git and yum-utils)
#--------------------------------------------------------------------------------
echo "--> Installing Git and yum-utils..."
# Git added as requested
yum install -y git yum-utils

# Install Docker
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
usermod -aG docker opc

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

#--------------------------------------------------------------------------------
# Install OCI CLI (FIXED: Ensures installation as opc user and persistent PATH)
#--------------------------------------------------------------------------------
echo "--> Installing OCI CLI as opc user..."
# This command runs the installer as the 'opc' user, ensuring files go to /home/opc/bin 
# and the user's .bashrc is ideally updated by the installer itself.
su - opc -c 'bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults --exec-dir /home/opc/bin'

# Manual PATH addition for guarantee (writes to the opc user's profile)
echo 'export PATH="/home/opc/bin:$PATH"' >> /home/opc/.bashrc

# Manual PATH addition for all users (writes to a system-wide script)
echo 'export PATH="/home/opc/bin:$PATH"' >> /etc/profile.d/oci-cli.sh
chmod +x /etc/profile.d/oci-cli.sh

# Note: Directly using 'source /home/opc/.bashrc' is NOT necessary here 
# because the cloud-init script ends after this. The next command executed 
# is the user logging in via SSH, which will automatically source the files 
# we just modified (.bashrc and /etc/profile.d/oci-cli.sh).

echo "Bastion setup completed at $(date)"
EOT
}



# ============================================
# BASTION INSTANCE
# ============================================

resource "oci_core_instance" "bastion" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = var.bastion_display_name
  shape               = var.bastion_shape

  dynamic "shape_config" {
    for_each = var.bastion_shape == "VM.Standard.E3.Flex" || var.bastion_shape == "VM.Standard.E4.Flex" || var.bastion_shape == "VM.Standard.A1.Flex" ? [var.bastion_shape_config] : []
    content {
      ocpus         = shape_config.value.ocpus
      memory_in_gbs = shape_config.value.memory_in_gbs
    }
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.bastion_images.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size
  }

  create_vnic_details {
    subnet_id              = var.create_bastion_subnet ? oci_core_subnet.bastion_subnet[0].id : var.existing_subnet_id
    display_name           = "bastion-primary-vnic"
    assign_public_ip       = true
    skip_source_dest_check = false
    nsg_ids                = var.nsg_ids
  }

  # Then in the instance metadata:
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init_script)
  }

  preserve_boot_volume = false

  freeform_tags = merge(
    var.tags,
    {
      "Name"        = var.bastion_display_name
      "Type"        = "Bastion"
      "Environment" = var.environment
      "Purpose"     = "OKE Workshop"
    }
  )
}

# ============================================
# WAIT FOR CLOUD-INIT TO COMPLETE (Optional)
# ============================================

resource "null_resource" "wait_for_cloud_init" {
  count = var.wait_for_cloud_init ? 1 : 0

  depends_on = [oci_core_instance.bastion]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "timeout 600 cloud-init status --wait || true",
      "echo 'Cloud-init completed'",
      "echo ''",
      "echo '========================================'",
      "echo '=== Bastion Host Information ==='",
      "echo '========================================'",
      "echo 'Hostname:' $(hostname)",
      "echo 'IP Address:' $(hostname -I | awk '{print $1}')",
      "echo ''",
      "echo '=== Installed Tools ==='",
      "docker --version 2>/dev/null || echo 'Docker: Not installed'",
      "kubectl version --client --short 2>/dev/null || echo 'kubectl: Not installed'",
      "oci --version 2>/dev/null || echo 'OCI CLI: Not installed'",
      "helm version --short 2>/dev/null || echo 'Helm: Not installed'",
      "git --version 2>/dev/null || echo 'Git: Not installed'",
      "echo ''",
      "echo '=== Sample Application ==='",
      "if [ -d /home/opc/customer-management-app ]; then",
      "  echo 'Sample app cloned to: /home/opc/customer-management-app'",
      "else",
      "  echo 'Sample app not found'",
      "fi",
      "echo ''",
      "echo '=== Kubeconfig ==='",
      "if [ -f /home/opc/.kube/config ]; then",
      "  echo 'Kubeconfig configured'",
      "  kubectl get nodes --no-headers 2>/dev/null | wc -l | xargs -I {} echo 'Cluster nodes: {}'",
      "else",
      "  echo 'Kubeconfig not configured'",
      "fi",
      "echo ''",
      "echo '========================================'",
      "echo '=== Bastion Setup Complete! ==='",
      "echo '========================================'",
    ]

    connection {
      type        = "ssh"
      user        = "opc"
      private_key = var.ssh_private_key
      host        = oci_core_instance.bastion.public_ip
      timeout     = "15m"
    }
  }
}


