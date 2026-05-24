{ ... }:
{
  xdg.configFile."containers/policy.json".text = builtins.toJSON {
    default = [ { type = "insecureAcceptAnything"; } ];
  };
}
