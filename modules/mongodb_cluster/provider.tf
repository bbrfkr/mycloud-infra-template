terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0"
    }
  }
}

provider "openstack" {
  auth_url = "https://keystone.dynamis.bbrfkr.net/v3"
}