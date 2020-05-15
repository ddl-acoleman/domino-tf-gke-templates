variable "cluster" {
  type        = string
  default     = null
  description = "The Domino Cluster name and must be unique in the GCP Project. Defaults to workspace name."
}

variable "description" {
  type    = string
  default = "The Domino K8s Cluster"
}

variable "project" {
  type        = string
  default     = "domino-eng-platform-dev"
  description = "GCP Project ID"
}

variable "location" {
  type        = string
  default     = "us-east4-a"
  description = "The location (region or zone) of the cluster. A zone creates a single master. Specifying a region creates replicated masters accross all zones"
}

variable "filestore_capacity_gb" {
  type        = number
  default     = 1024
  description = "Filestore Instance size (GB) for the cluster nfs shared storage"
}

variable "filestore_disabled" {
  type        = bool
  default     = false
  description = "Do not provision a Filestore instance (mostly to avoid GCP Filestore API issues)"
}

variable "enable_tpu" {
    type            = bool
    default         = false
    description     = "Do not enable tpu for K8S cluster."
}

variable "enable_vertical_pod_autoscaling" {
  type        = bool
  default     = true
  description = "Enable GKE vertical scaling"
}

variable "master_authorized_networks_config" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
  ]
  description = "Configuration options for master authorized networks."
}

variable "enable_network_policy" {
  type    = bool
  default = true
}

variable "enable_pod_security_policy" {
  type    = bool
  default = false
}

variable "platform_nodes_max" {
  type    = number
  default = 3
}

variable "platform_nodes_min" {
  type    = number
  default = 3
}

variable "platform_nodes_preemptible" {
  type    = bool
  default = true
}

variable "platform_node_type" {
  type    = string
  default = "n1-standard-8"
}

variable "platform_nodes_ssd_gb" {
  type    = number
  default = 128
}

variable "compute_nodes_max" {
  type    = number
  default = 20
}

variable "compute_nodes_min" {
  type    = number
  default = 1
}

variable "compute_nodes_preemptible" {
  type    = bool
  default = true
}

variable "compute_node_type" {
  type    = string
  default = "n1-standard-8"
}

variable "compute_nodes_ssd_gb" {
  type    = number
  default = 400
}
variable "gke_release_channel" {
  type        = string
  default     = "REGULAR"
  description = "GKE K8s release channel for master"
}

variable "platform_namespace" {
  type    = string
  default = "domino-platform"
}
