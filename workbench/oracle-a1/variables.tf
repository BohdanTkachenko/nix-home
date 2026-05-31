variable "region" {
  description = "OCI region identifier, e.g. us-ashburn-1."
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment for all resources; the tenancy root OCID works."
  type        = string
}

variable "availability_domain_number" {
  description = "Availability domain to launch in (1-based). A1 capacity varies per AD."
  type        = number
  default     = 1
}

variable "instance_name" {
  description = "Display name for the instance and its derived network/image resources."
  type        = string
  default     = "workbench"
}

variable "ocpus" {
  description = "vCPUs for the A1.Flex shape (Always Free max 4)."
  type        = number
  default     = 4
}

variable "memory_in_gbs" {
  description = "RAM in GB for the A1.Flex shape (Always Free max 24)."
  type        = number
  default     = 24
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size; the ext4 root auto-grows to fill it (Always Free block storage is 200 GB total)."
  type        = number
  default     = 200
}

variable "namespace" {
  description = "Object Storage namespace holding the image (oci os ns get)."
  type        = string
}

variable "image_bucket" {
  description = "Bucket holding the uploaded NixOS qcow2."
  type        = string
  default     = "tofu-state"
}

variable "image_object_name" {
  description = "Object name of the uploaded qcow2 (oci os object put …)."
  type        = string
  default     = "nixos-aarch64.qcow2"
}

variable "image_capability_schema_version" {
  description = "OCI global image capability schema version name."
  type        = string
  default     = "2024-03-27"
}
