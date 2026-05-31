output "public_ip" {
  description = "Public IPv4 of the instance."
  value       = oci_core_instance.workbench.public_ip
}

output "ssh_command" {
  description = "SSH login (keys baked into the NixOS image for user dan)."
  value       = "ssh dan@${oci_core_instance.workbench.public_ip}"
}

output "image_id" {
  description = "OCID of the imported custom image."
  value       = oci_core_image.nixos.id
}

output "availability_domain" {
  description = "Availability domain the instance launched in."
  value       = local.availability_domain
}
