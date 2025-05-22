# -----------------------------------------------------------------------------
# GKE Private Cluster and Network Configuration
# Configured for access from a self-hosted runner within the same VPC subnet.
# Assumes an existing VPC network.
# -----------------------------------------------------------------------------
data "google_compute_network" "vpc" {
  name    = "${var.cluster_name}-vpc" # Reference the existing VPC by its name
  project = var.project_id
}

# Subnet for the GKE cluster (and your self-hosted runner)
# This subnet will still be created by Terraform, as it's specific to this GKE deployment.
resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.cluster_name}-subnet"
  ip_cidr_range            = "10.2.0.0/16"
  region                   = var.region
  # CHANGE: Referencing the existing VPC via the 'data' block
  network                  = data.google_compute_network.vpc.self_link
  project                  = var.project_id
  private_ip_google_access = true # Enable Private Google Access for nodes to reach Google APIs privately

  # Secondary IP ranges for GKE pods and services (IP aliasing)
  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.48.0.0/14" # Example range for pods
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.52.0.0/20" # Example range for services
  }
}

# --- GKE Cluster Resources ---
resource "google_container_cluster" "private_cluster" {
  name                     = var.cluster_name
  location                 = var.region
  initial_node_count       = var.node_count # Initial node count, will be managed by node pool
  remove_default_node_pool = true           # Remove the default node pool to use our custom one
  enable_shielded_nodes    = true           # Enhance node security

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link
  project    = var.project_id

  # Private Cluster Configuration
  private_cluster_config {
    enable_private_nodes    = true  # GKE worker nodes only have internal IPs
    enable_private_endpoint = true  # Enables a public endpoint for the control plane (secured by authorized networks)
    master_ipv4_cidr_block  = "172.16.0.0/28" # CIDR range for the master's internal IP address.
                                            # This is a private RFC1918 range within your VPC.
  }

  # IP Allocation Policy (VPC-native cluster with IP aliasing)
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range[1].range_name
  }

  # Master Authorized Networks Config
  # IMPORTANT: This allows access to the public control plane endpoint from specified CIDRs.
  # We are authorizing the subnet where the self-hosted runner resides.
  master_authorized_networks_config {
    cidr_blocks {
      # CHANGE: Authorizing the entire subnet where the self-hosted runner is located.
      # This is the most practical way to ensure connectivity from the runner.
      cidr_block   = google_compute_subnetwork.subnet.ip_cidr_range
      display_name = "SelfHostedRunnerSubnetAccess"
    }
    # If your previous 'private-access' was intended for the master_ipv4_cidr_block itself,
    # it's redundant here as the subnet access covers it.
    # If it was for other internal access, you can add it back:
    # cidr_blocks {
    #   cidr_block   = "172.16.0.0/28"
    #   display_name = "private-access"
    # }
  }

  # Other important settings
  release_channel {
    channel = "REGULAR" # Choose your desired release channel (RAPID, REGULAR, STABLE)
  }

  # Optionally enable logging and monitoring for better observability
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }
}

# Node Pool for the GKE cluster
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.private_cluster.name
  node_count = var.node_count
  project    = var.project_id

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform", # Full access to all Cloud APIs
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/devstorage.read_only", # For pulling images from GCR
    ]

    labels = {
      env = var.cluster_name
    }

    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    tags         = ["gke-node", "${var.cluster_name}-node"]
    metadata = {
      disable-legacy-endpoints = "true" # Best practice for security
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# --- Outputs for easier access to cluster information ---
output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.private_cluster.name
}

output "cluster_endpoint" {
  description = "The public endpoint of the GKE cluster control plane."
  value       = google_container_cluster.private_cluster.endpoint
}

output "region" {
  description = "The region where the GKE cluster is deployed."
  value       = var.region
}

output "master_authorized_networks_configured" {
  description = "The CIDR blocks authorized to access the GKE control plane."
  value       = google_container_cluster.private_cluster.master_authorized_networks_config[0].cidr_blocks
}

output "subnet_cidr_range" {
  description = "The IP CIDR range of the GKE and runner subnet."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}
