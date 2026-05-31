# Import the NixOS qcow2 (uploaded out-of-band to Object Storage) as a custom
# image, and register the A1 shape + capabilities so it boots on Ampere.
resource "oci_core_image" "nixos" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.instance_name}-nixos-aarch64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type       = "objectStorageTuple"
    namespace_name    = var.namespace
    bucket_name       = var.image_bucket
    object_name       = var.image_object_name
    source_image_type = "QCOW2"
  }

  timeouts {
    create = "60m"
  }
}

# Without this the launch fails with "shape not compatible with image".
resource "oci_core_shape_management" "a1_compat" {
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.nixos.id
  shape_name     = "VM.Standard.A1.Flex"
}

# Without correct capabilities the instance "boots but is unresponsive".
resource "oci_core_compute_image_capability_schema" "nixos_caps" {
  compartment_id                                      = var.compartment_ocid
  image_id                                            = oci_core_image.nixos.id
  compute_global_image_capability_schema_version_name = var.image_capability_schema_version

  schema_data = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })
    "Compute.LaunchMode" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "EMULATED", "CUSTOM", "NATIVE"]
    })
    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "ISCSI", "SCSI", "IDE", "NVME"]
    })
    "Network.AttachmentType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "E1000", "VFIO", "VDPA"]
    })
  }
}
