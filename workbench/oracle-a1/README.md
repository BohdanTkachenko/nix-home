# Oracle Cloud A1 — NixOS via custom image (OpenTofu)

Deploys an Always-Free **Ampere A1** (4 OCPU / 24 GB, aarch64) running NixOS, built from a
**custom image** rather than kexec/`nixos-anywhere` (which wedges reliably on OCI A1). The
`workbench` host in the root flake is built around nixpkgs' `oci-image.nix` (GRUB-EFI, ext4
root that auto-grows, qemu-guest), so the image is a complete, ready-to-boot system.

State lives in **OCI Object Storage** via its S3-compatible API (`backend "s3"`).

## What it creates

- VCN + public subnet + internet gateway + route + security list (inbound SSH).
- A custom **image** imported from the uploaded qcow2, registered for `VM.Standard.A1.Flex`
  with UEFI/paravirtualized capabilities.
- One A1 instance booted from that image (public IPv4, boot volume grown to 200 GB).

## Prerequisites (one time)

1. **OCI auth:** `~/.oci/config` via `oci setup config` (passwordless RSA key; see git history).
2. **State backend:** a `tofu-state` bucket + a **Customer Secret Key** exported as
   `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (`.env`). `cp backend.hcl.example backend.hcl`
   and set the namespace endpoint; `cp terraform.tfvars.example terraform.tfvars` and fill in.

## Build + deploy

The aarch64 image is built **natively on the running A1 box** (fast; no cross-compilation).

1. **Build the image on the A1** (currently Ubuntu, reachable as `ubuntu@`):
   ```bash
   ssh ubuntu@<ip>
   # install Nix (multi-user) + enable flakes, then:
   git clone https://github.com/BohdanTkachenko/nix-home && cd nix-home
   nix build .#packages.aarch64-linux.workbench-image     # → result/nixos.qcow2
   ```
2. **Upload the qcow2** to the bucket (from the A1, using its OCI creds):
   ```bash
   oci os object put -bn tofu-state --name nixos-aarch64.qcow2 --file result/nixos.qcow2 --force
   ```
3. **Apply** from your laptop (`.env` loaded via direnv):
   ```bash
   cd workbench/oracle-a1
   tofu init -backend-config=backend.hcl
   tofu apply
   ```
   This imports the image (30–45 min), registers the shape/capabilities, and **replaces** the
   bootstrap Ubuntu instance with one booted from the NixOS image. Then:
   ```bash
   ssh dan@$(tofu output -raw public_ip)
   ```

> **A1 capacity:** if `apply` hits "Out of host capacity," bump `availability_domain_number`
> (1/2/3) and re-apply.
>
> **"Boots but unresponsive":** re-check the capability schema (`image.tf`) — that's the known
> A1 image-capabilities gotcha.

## Day-2

`dan`'s SSH keys are baked into the image (`nixos/user.nix`), and the box is a full `workbench`
NixOS system. Update it with `nixos-rebuild switch --flake .#workbench` on the box (or pull-based
via the hydration service). Rebuilding the *image* is only needed for disk-layout/bootloader
changes.
