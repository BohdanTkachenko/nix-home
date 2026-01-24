{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ keychron-udev-rules ];
}
