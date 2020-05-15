terraform {
  required_version = ">= 0.12.0"
  backend "gcs" {
    bucket = "<Terraform State Bucket in GCP>"
    prefix = "terraform/state"
  }
}

locals {
  cluster = var.cluster == null ? terraform.workspace : var.cluster
  enable_private_endpoint = length(var.master_authorized_networks_config) == 0
  # Converts a cluster's location to a zone/region. A 'location' may be a region or zone: a region becomes the '[region]-a' zone.
  region = length(split("-", var.location)) == 2 ? var.location : substr(var.location, 0, length(var.location) - 2)
  zone = length(split("-", var.location)) == 3 ? var.location : format("%s-a", var.location)
}

provider "google" {
  project = var.project
  region = local.region
}

provider "google-beta" {
  project = var.project
  region = local.region
}

data "google_project" "domino" {
  project_id = var.project
}

resource "google_project_iam_member" "k8s-service-agent-kms" {
  project = var.project
  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member = "serviceAccount:service-${data.google_project.domino.number}@container-engine-robot.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "k8s-service-agent-sa-admin" {
  project = var.project
  role = "roles/iam.serviceAccountAdmin"
  member = "serviceAccount:service-${data.google_project.domino.number}@container-engine-robot.iam.gserviceaccount.com"
}

resource "google_compute_global_address" "static_ip" {
  name = "domino-${var.cluster}"
}

resource "google_compute_network" "vpc_network" {
  name = "domino-${var.cluster}"
  # This helps lowers our subnet quota utilization
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name = "domino-${var.cluster}"
  ip_cidr_range = "10.138.0.0/20"
  network = google_compute_network.vpc_network.self_link
  private_ip_google_access = true
  description = "${local.cluster} default network"
}

resource "google_storage_bucket" "bucket" {
  name = "${var.project}-dominodatalab-${local.cluster}"
  #remove zone from location
  location = local.region

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
  force_destroy = true
}

resource "google_filestore_instance" "nfs" {
  name = "domino-${var.cluster}"
  tier = "STANDARD"
  zone = local.zone

  file_shares {
    capacity_gb = var.filestore_capacity_gb
    name = "share1"
  }

  networks {
    network = google_compute_network.vpc_network.name
    modes = [
      "MODE_IPV4"]
  }

  count = var.filestore_disabled ? 0 : 1

}

resource "google_container_cluster" "domino_cluster" {
  provider = google-beta

  name = "domino-${local.cluster}"
  location = var.location
  description = var.description

  release_channel {
    channel = var.gke_release_channel
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  network = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.default.self_link

  enable_tpu = var.enable_tpu

  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }

  ip_allocation_policy {}

  resource_labels = {
    "uuid" = var.cluster
  }

  # Application-layer Secrets Encryption
  database_encryption {
    state = "ENCRYPTED"
    key_name = google_kms_crypto_key.crypto_key.self_link
  }

  workload_identity_config {
    identity_namespace = "${data.google_project.domino.project_id}.svc.id.goog"
  }

  network_policy {
    provider = "CALICO"
    enabled = var.enable_network_policy
  }

  pod_security_policy_config {
    enabled = var.enable_pod_security_policy
  }

  depends_on = [
    google_project_iam_member.k8s-service-agent-kms,
    google_project_iam_member.k8s-service-agent-sa-admin]
}

resource "google_container_node_pool" "platform" {
  name = "platform"
  location = google_container_cluster.domino_cluster.location
  cluster = google_container_cluster.domino_cluster.name

  initial_node_count = var.platform_nodes_max
  autoscaling {
    max_node_count = var.platform_nodes_max
    min_node_count = var.platform_nodes_min
  }

  node_config {
    preemptible = false
    machine_type = var.platform_node_type

    labels = {
      "dominodatalab.com/node-pool" = "platform"
    }

    disk_size_gb = var.platform_nodes_ssd_gb
    local_ssd_count = 1
  }

  management {
    auto_repair = true
    auto_upgrade = true
  }

  timeouts {
    delete = "20m"
  }
}

resource "google_container_node_pool" "compute" {
  name = "compute"
  location = google_container_cluster.domino_cluster.location
  cluster = google_container_cluster.domino_cluster.name

  initial_node_count = var.compute_nodes_min
  autoscaling {
    max_node_count = var.compute_nodes_max
    min_node_count = var.compute_nodes_min
  }

  node_config {
    preemptible = false
    machine_type = var.compute_node_type

    labels = {
      "domino/build-node" = "true"
      "dominodatalab.com/build-node" = "true"
      "dominodatalab.com/node-pool" = "default"
    }

    disk_size_gb = var.compute_nodes_ssd_gb
    local_ssd_count = 1
  }

  management {
    auto_repair = true
    auto_upgrade = true
  }

  timeouts {
    delete = "20m"
  }
}

resource "google_kms_key_ring" "key_ring" {
  name     = "domino-${var.cluster}"
  location = local.region

}

resource "google_kms_crypto_key" "crypto_key" {
  name            = "domino-${var.cluster}"
  key_ring        = google_kms_key_ring.key_ring.self_link
  rotation_period = "86400s"
  purpose         = "ENCRYPT_DECRYPT"
}