{ config, lib, pkgs, ... }:
let
  # Helper to resolve secret string depending on whether it is for Claude (env var) or Antigravity (SOPS placeholder)
  getSecret = { isClaude, name, envVar }:
    if isClaude then
      "\${${envVar}}"
    else
      config.sops.placeholder."${name}";

  # @playwright/mcp distributed on npm can't run on NixOS out of the box: it
  # defaults to the system 'chrome' channel (/opt/google/chrome/chrome, absent
  # on NixOS) and its self-downloaded browsers aren't patched for the Nix
  # dynamic linker. Wrap it to use the prebuilt Chromium from nixpkgs'
  # playwright-driver via --executable-path, which sidesteps the browser-
  # revision matching entirely (the npm package bundles a much newer
  # playwright-core than nixpkgs ships). The chromium-<rev> dir name changes
  # each release, so resolve it with a runtime glob rather than hardcoding it.
  playwrightMcp = pkgs.writeShellApplication {
    name = "playwright-mcp";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      # Pin the binary explicitly; do NOT export PLAYWRIGHT_BROWSERS_PATH — when
      # set to the Nix store path, @playwright/mcp tries to create its session
      # profile dir *inside* it (read-only) and dies with ENOENT. --isolated
      # keeps the profile in memory so nothing is written under the store.
      export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
      chromium=$(echo ${pkgs.playwright-driver.browsers}/chromium-*/chrome-linux/chrome)
      exec npx -y @playwright/mcp@latest \
        --headless \
        --browser chromium \
        --executable-path "$chromium" \
        --no-sandbox \
        --isolated \
        "$@"
    '';
  };
in
{
  # Centralized SOPS secrets
  sops.secrets.github-pat = lib.mkIf config.my.secrets.sops.enable {
    sopsFile = ./secrets/claude-code.yaml;
    key = "github_pat";
  };
  sops.secrets.plane-api-key = lib.mkIf config.my.secrets.sops.enable {
    sopsFile = ./secrets/claude-code.yaml;
    key = "plane_api_key";
  };
  sops.secrets.plane-workspace-slug = lib.mkIf config.my.secrets.sops.enable {
    sopsFile = ./secrets/claude-code.yaml;
    key = "plane_workspace_slug";
  };
  sops.secrets.claude-ha-mcp-url = lib.mkIf config.my.secrets.sops.enable {
    sopsFile = ./secrets/claude-code.yaml;
    key = "ha_mcp_url";
  };

  # Exposed helper for generating configs (nested in attribute set to satisfy Home Manager types)
  lib.mcp = {
    makeMcpServers = { isClaude }:
      let
        githubPat = getSecret { inherit isClaude; name = "github-pat"; envVar = "GITHUB_PERSONAL_ACCESS_TOKEN"; };
        planeApiKey = getSecret { inherit isClaude; name = "plane-api-key"; envVar = "PLANE_API_KEY"; };
        planeWorkspaceSlug = getSecret { inherit isClaude; name = "plane-workspace-slug"; envVar = "PLANE_WORKSPACE_SLUG"; };
        claudeHaMcpUrl = getSecret { inherit isClaude; name = "claude-ha-mcp-url"; envVar = "CLAUDE_HA_MCP_URL"; };
      in
      {
        home-assistant =
          if isClaude then {
            type = "http";
            url = claudeHaMcpUrl;
            oauth = {
              clientId = "http://localhost:48721";
              callbackPort = 48721;
            };
          } else {
            command = lib.getExe' pkgs.nodejs "npx";
            args = [
              "-y"
              "mcp-remote"
              claudeHaMcpUrl
              "48721"
              "--static-oauth-client-info"
              (builtins.toJSON {
                client_id = "http://localhost:48721";
                redirect_uris = [ "http://localhost:48721/oauth/callback" ];
              })
            ];
            env = {
              PATH = "${lib.makeBinPath [
                pkgs.nodejs
                pkgs.bash
                pkgs.coreutils
              ]}";
            };
          };

        plane = {
          type = "http";
          headers = {
            Authorization = "Bearer ${planeApiKey}";
            X-Workspace-slug = planeWorkspaceSlug;
          };
        } // (if isClaude then {
          url = "https://mcp.plane.so/http/api-key/mcp";
        } else {
          serverURL = "https://mcp.plane.so/http/api-key/mcp";
        });

        playwright = {
          command = lib.getExe playwrightMcp;
          args = [ ];
          env = {
            PATH = "${lib.makeBinPath [
              pkgs.nodejs
              pkgs.bash
              pkgs.coreutils
            ]}";
          };
        };
      } // (if isClaude then {
        github = {
          command = lib.getExe pkgs.podman;
          args = [
            "run"
            "-i"
            "--rm"
            "-e"
            "GITHUB_PERSONAL_ACCESS_TOKEN"
            "ghcr.io/github/github-mcp-server"
          ];
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = githubPat;
          };
        };
      } else {
        github-mcp-server = {
          command = lib.getExe pkgs.podman;
          args = [
            "run"
            "-i"
            "--rm"
            "-e"
            "GITHUB_PERSONAL_ACCESS_TOKEN"
            "ghcr.io/github/github-mcp-server"
          ];
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = githubPat;
          };
        };
        sequential-thinking = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-sequential-thinking"
          ];
          env = {
            PATH = "${lib.makeBinPath [
              pkgs.nodejs
              pkgs.bash
              pkgs.coreutils
            ]}";
          };
        };
        chrome-devtools-mcp = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [
            "-y"
            "chrome-devtools-mcp@latest"
          ];
          env = {
            PATH = "${lib.makeBinPath [
              pkgs.nodejs
              pkgs.bash
              pkgs.coreutils
            ]}";
          };
        };
      });
  };
}
