{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  pkgs-antigravity-cli,
  ...
}:
let
  pinToCCD1 = import ../../lib/pin-to-ccd1.nix { inherit pkgs; };
  settings = import ./vscode-settings.nix { inherit pkgs pkgs-unstable; };
  settingsFile = (pkgs.formats.json { }).generate "antigravity-settings.json" settings;

  mcpConfig = {
    mcpServers = {
      sequential-thinking = {
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
      };
      chrome-devtools-mcp = {
        command = "npx";
        args = [
          "-y"
          "chrome-devtools-mcp@latest"
        ];
      };
      home-assistant = {
        command = "bash";
        args = [
          "-c"
          "npx -y mcp-remote \"$CLAUDE_HA_MCP_URL\" 48721 --static-oauth-client-info '{\"client_id\": \"http://localhost:48721\", \"redirect_uris\": [\"http://localhost:48721/oauth/callback\"]}'"
        ];
      };
      github-mcp-server = {
        command = "docker";
        args = [
          "run"
          "-i"
          "--rm"
          "-e"
          "GITHUB_PERSONAL_ACCESS_TOKEN"
          "ghcr.io/github/github-mcp-server"
        ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "\${env:GITHUB_PERSONAL_ACCESS_TOKEN}";
        };
      };
      plane = {
        type = "http";
        disabled = true;
        serverURL = "https://mcp.plane.so/http/api-key/mcp";
        headers = {
          Authorization = "Bearer \${env:PLANE_API_KEY}";
          X-Workspace-slug = "\${env:PLANE_WORKSPACE_SLUG}";
        };
      };
    };
  };
  mcpConfigFile = (pkgs.formats.json { }).generate "antigravity-mcp-config.json" mcpConfig;

  extensions = import ./vscode-extensions.nix { inherit pkgs lib config; isAntigravity = true; };

  antigravityPkg = pkgs-unstable.antigravity.fhsWithPackages (ps: with ps; [
    nodejs
    python3
  ]);

  antigravityWithExtensions = pkgs.vscode-with-extensions.override {
    vscode = antigravityPkg;
    vscodeExtensions = extensions;
  };

  exportSecret =
    file: var:
    ''export ${var}="$(cat "$HOME/.config/sops-nix/secrets/${file}" 2>/dev/null || true)"'';

  antigravityWrapped = pkgs.symlinkJoin {
    name = "antigravity-wrapped";
    paths = [ antigravityWithExtensions ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/antigravity \
        --run '${exportSecret "github-pat" "GITHUB_PERSONAL_ACCESS_TOKEN"}' \
        --run '${exportSecret "plane-api-key" "PLANE_API_KEY"}' \
        --run '${exportSecret "plane-workspace-slug" "PLANE_WORKSPACE_SLUG"}' \
        --run '${exportSecret "claude-ha-mcp-url" "CLAUDE_HA_MCP_URL"}'
    '';
  };
in
{
  home.packages = [
    (pinToCCD1 antigravityWrapped)
    pkgs-antigravity-cli.antigravity-cli
  ];

  home.file.".local/share/pixmaps/antigravity.png".source = "${antigravityPkg}/share/pixmaps/antigravity.png";
  home.file.".local/share/icons/antigravity.png".source = "${antigravityPkg}/share/pixmaps/antigravity.png";

  anti-drift.files = {
    ".config/Antigravity/User/settings.json" = {
      source = settingsFile;
      json = true;
    };
    ".gemini/antigravity/mcp_config.json" = {
      source = mcpConfigFile;
      json = true;
    };
  };
}
