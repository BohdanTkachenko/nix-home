{ config, lib, pkgs, ... }:
let
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
  # Directory holding the AI/MCP secret files (github-pat, gitlab-pat,
  # plane-api-key, plane-workspace-slug, claude-ha-mcp-url), read at runtime by
  # the Claude Code wrapper. Supplied by the private overlay (sops-nix); null on
  # a public build, in which case the wrapper exports no tokens.
  options.my.ai.secretsDir = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    example = "/home/dan/.config/sops-nix/secrets";
    description = "Directory of AI/MCP secret files read by the Claude Code wrapper.";
  };

  # Exposed helper for generating MCP server configs. `secrets` injects the
  # secret-bearing strings — env-var references (${VAR}) for Claude, which
  # expands them at load time, or sops placeholders for Antigravity, which bakes
  # the real values into its rendered config (see private overlay). Keeping the
  # secret resolution out of this module is what lets it stay sops-free.
  config.lib.mcp = {
    makeMcpServers = { isClaude, secrets }:
      let
        inherit (secrets)
          githubPat
          gitlabPat
          planeApiKey
          planeWorkspaceSlug
          claudeHaMcpUrl
          ;
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

        # Third-party GitLab MCP server (zereight/gitlab-mcp), run as a stdio
        # container like the github server above. Used instead of GitLab's
        # native server, which requires Premium/Ultimate + Duo (not available
        # on this account). Authenticates with a personal access token (api
        # scope; use read_api + GITLAB_READ_ONLY_MODE for read-only).
        gitlab = {
          command = lib.getExe pkgs.podman;
          args = [
            "run"
            "-i"
            "--rm"
            "-e"
            "GITLAB_PERSONAL_ACCESS_TOKEN"
            "-e"
            "GITLAB_API_URL=https://gitlab.com/api/v4"
            "docker.io/zereight050/gitlab-mcp"
          ];
          env = {
            GITLAB_PERSONAL_ACCESS_TOKEN = gitlabPat;
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
