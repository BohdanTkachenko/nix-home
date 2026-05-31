terraform {
  # 1.10+ for native S3 state locking (no DynamoDB).
  required_version = ">= 1.10"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }

  # State in OCI Object Storage via its S3-compatible API; the skip_* and
  # path-style flags are required for that endpoint. bucket/key/region/endpoint
  # come from backend.hcl, credentials from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY.
  backend "s3" {
    use_path_style              = true
    use_lockfile                = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}
