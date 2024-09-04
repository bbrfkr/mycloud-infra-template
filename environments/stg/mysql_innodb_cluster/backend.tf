terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0"
    }
  }
  backend "s3" {
    bucket = "mycloud-tfstates"
    key    = "stg/mysql_innodb_cluster"
    endpoints = {
      s3 = "https://swift.dynamis.bbrfkr.net"
    }
    region                      = "nova"
    profile                     = "openstack"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
