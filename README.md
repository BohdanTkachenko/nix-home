# nix-home

## Installation

```sh
jj git clone https://github.com/BohdanTkachenko/nix-home $HOME/.config/nix
cd $HOME/.config/nix
make setup
make
```

## TPM2 Enrollment

To enroll TPM2 for automatic LUKS unlock:

```sh
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-partlabel/disk-main-luks
```

To wipe existing TPM2 enrollment and re-enroll:

```sh
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/disk/by-partlabel/disk-main-luks
```
