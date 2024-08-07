data "terraform_remote_state" "global_common" {
  backend = "s3"
  config = {
    bucket = "mycloud-tfstates"
    key    = "global/common"
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

data "terraform_remote_state" "common" {
  backend = "s3"
  config = {
    bucket = "mycloud-tfstates"
    key    = "stg/common"
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
