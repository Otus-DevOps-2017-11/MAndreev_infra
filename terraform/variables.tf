variable project {
  description = "Project ID"
}

variable region {
  description = "Region"

  default = "europe-west3"
}

variable app_zone {
  description = "App zone"

  default = "europe-west3-b"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable disk_image {
  description = "Disk image"
}

variable private_key_path {
  description = "Path to the private key for private key"
}
