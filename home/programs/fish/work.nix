{ ... }:
{
  imports = [ ./common.nix ];
  programs.fish.interactiveShellInit = ''
    source_google_fish_package autogcert
    source_google_fish_package buildfix
    source_google_fish_package citc_prompt
    source_google_fish_package hb
    source_google_fish_package pastebin
  '';
}
