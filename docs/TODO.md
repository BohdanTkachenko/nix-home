* 2025-11-03 10:18:15 [unread]

  A new module 'programs.mcp' is now available for managing Model
  Context Protocol (MCP) server configurations.
  
  The 'programs.mcp.servers' option allows you to define MCP servers
  in a central location. These configurations can be automatically
  integrated into applications that support MCP.
  
  Two modules now support MCP integration:
  
  - 'programs.opencode.enableMcpIntegration': Integrates MCP servers
    into OpenCode's configuration.
  
  - 'programs.vscode.profiles.<name>.enableMcpIntegration': Integrates
    MCP servers into VSCode profiles.
  
  When integration is enabled, servers from 'programs.mcp.servers' are
  merged with application-specific MCP settings, with the latter taking
  precedence. This allows you to define MCP servers once and reuse them
  across multiple applications.
  


* 2025-10-31 12:00:00 [unread]

  services.local-ai: new module
  
  Added LocalAI, a free, Open Source OpenAI alternative.
  
* 2025-10-26 21:07:01 [unread]

  A new module is available: `programs.zapzap`
  
  ZapZap brings the WhatsApp experience on Linux closer to that of a native application.
  Since Meta does not provide a public API for third-party applications, ZapZap is developed
  as a Progressive Web Application (PWA), built with PyQt6 + PyQt6-WebEngine.
  
* 2025-10-26 07:19:48 [unread]

  A new module is available: `targets.genericLinux.gpu`
  
  This module provides integration of GPU drivers for non-NixOS systems. It is a
  simpler alternative to the existing `targets.genericLinux.nixGL` module. See the
  Home Manager user manual for more information.
  
* 2025-10-25 14:45:39 [unread]

  The home-manager auto-upgrade service now supports updating Nix flakes.
  
  Enable this by setting `services.home-manager.autoUpgrade.useFlake = true;`.
  
  The flake directory can be configured with `services.home-manager.autoUpgrade.flakeDir`,
  which defaults to the configured XDG config home (typically `~/.config/home-manager`).
  
* 2025-09-12 15:02:45 [unread]

  A new module is available: 'programs.jjui'
  
  jjui is a terminal user interface for jujutsu version control system.
  
* 2025-08-30 16:07:19 [unread]

  A new module is available: 'services.shpool'.
  
  shpool is a service that enables session persistence by allowing the creation of named shell sessions owned by shpool so that the session is not lost if the connection drops.
  
  Read about it at https://github.com/shell-pool/shpool
  
