{
  pkgs-unstable,
  ...
}:
{
  home.packages = with pkgs-unstable; [
    cargo
    rustc
  ];

  home.sessionPath = [ "$HOME/.cargo/bin" ];
}
