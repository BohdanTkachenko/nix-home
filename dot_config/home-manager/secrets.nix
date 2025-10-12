{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/dan/.config/age/dotfiles.key";
    secrets = {
      "geminiApiKey" = { };
    };
  };
}
