#service account with access to manage cluster
#static external ip address - request SSH firewall access from internal networks
#VM with Ubuntu 18.04 & docker installed

resource "google_service_account" "k8s-admin"{
    account_id = "${local.cluster}-k8s-admin"
    display_name = "${local.cluster}-k8s-admin"
}

resource "google_project_iam_member" "admin_kms" {
  project = var.project
  role    = "roles/cloudkms.admin"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_compute" {
  project = var.project
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_compute_instance" {
  project = var.project
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_network" {
  project = var.project
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_container" {
  project = var.project
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_dns" {
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_filestore" {
  project = var.project
  role    = "roles/file.editor"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_security" {
  project = var.project
  role    = "roles/iam.securityAdmin"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_service_account" {
  project = var.project
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

resource "google_project_iam_member" "admin_storage" {
  project = var.project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.k8s-admin.email}"
}

data "template_file" "workstation_startup_script"{
    template = file("${path.module}/workstation-startup-script.sh")
    vars = {
        cluster = "domino-${local.cluster}"
    }
}

resource "google_compute_address" "workstation_static_ip"{
    name        = "domino-${var.cluster}-workstation"
    region      = local.region
}

resource "google_compute_instance" "workstation" {
  name         = "domino-workstation"
  machine_type = "n1-standard-2"
  zone         = local.zone
  tags = ["domino-ssh"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20191211"
      size  = "20"
      type  = "pd-ssd"
    }
  }
  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.default.self_link
    access_config {
      nat_ip = google_compute_address.workstation_static_ip.address
    }
  }
  metadata_startup_script = data.template_file.workstation_startup_script.rendered
  service_account {
    email  =  google_service_account.k8s-admin.email
    #allow full access to all Cloud APIs, permission should be managed by what roles the service account has access to.
    scopes = ["cloud-platform"]
  }
  depends_on = [google_service_account.k8s-admin,google_compute_address.workstation_static_ip]
}
