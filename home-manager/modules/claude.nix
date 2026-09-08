{ config, pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    settings = {
    };
    # commands = { ... };
    # agents = { ... };
    # skills = { ... };
    # plugins = { ... };
    # mcpServers = { ... };
  };
}

