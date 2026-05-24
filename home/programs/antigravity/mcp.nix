{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ../ai/mcp.nix
  ];

  sops.templates."antigravity-mcp-config.json".content = builtins.toJSON {
    mcpServers = config.lib.mcp.makeMcpServers { isClaude = false; };
  };

  anti-drift.files = {
    ".gemini/config/mcp_config.json" = {
      source = config.sops.templates."antigravity-mcp-config.json".path;
      json = true;
    };
  };
}
