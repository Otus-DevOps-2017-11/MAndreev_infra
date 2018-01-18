provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

# Add some SSH Keys to a project metadata
resource "google_compute_project_metadata_item" "default" {
  key   = "ssh-keys"
  value = "appuser1:${file(var.public_key_path)}\nappuser2:${file(var.public_key_path)}"
}

resource "google_compute_instance" "app" {
  name         = "reddit-app-${count.index}"
  machine_type = "g1-small"
  zone         = "${var.app_zone}"
  count        = 2

  # Init boot disk image
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  # Init network interface
  network_interface {
    # Network
    network = "default"

    # Using ephemeral IP
    access_config {}
  }

  # Add ssh key
  metadata {
    sshKeys = "appuser:${file(var.public_key_path)}"
  }

  # Add tag
  tags = ["reddit-app"]

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  # Add puma.service
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  # Deploy script
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

# Add firewall
resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"

  # Network for firewall rule
  network = "default"

  # Rule port
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  # Rule ip range
  source_ranges = ["0.0.0.0/0"]

  # Tags for rule
  target_tags = ["reddit-app"]
}

# HTTP Balancer setting
# Add instance group
resource "google_compute_instance_group" "app-group" {
  name      = "app-group"
  instances = ["${google_compute_instance.app.*.self_link}"]
  zone      = "${var.app_zone}"

  named_port {
    name = "app-port"
    port = "9292"
  }
}

# Add healthcheck
resource "google_compute_http_health_check" "app-check" {
  name                = "app-check"
  request_path        = "/"
  port                = "9292"
  check_interval_sec  = 5
  timeout_sec         = 1
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# Add backend service
resource "google_compute_backend_service" "app-backend-service" {
  name        = "app-backend"
  port_name   = "app-port"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.app-group.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.app-check.self_link}"]
}

# Add mapping
resource "google_compute_url_map" "app-url-map" {
  name            = "app-url-map"
  default_service = "${google_compute_backend_service.app-backend-service.self_link}"
}

# Add proxy
resource "google_compute_target_http_proxy" "app-proxy" {
  name    = "app-proxy"
  url_map = "${google_compute_url_map.app-url-map.self_link}"
}

# Add forwarding rule
resource "google_compute_global_forwarding_rule" "app-forwarding-rule" {
  name       = "app-rule"
  target     = "${google_compute_target_http_proxy.app-proxy.self_link}"
  port_range = "80"
}
