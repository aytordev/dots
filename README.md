# dots

My personal Nix-based system configuration for macOS.

## Features

- Managed with Nix Flakes
- System configuration via nix-darwin
- User environment via home-manager
- Reproducible development environments

## Getting Started

1. Clone this repository
2. Run `nix develop` to enter the development shell
3. Use `darwin-rebuild switch --flake .#<hostname>` to apply configuration

## Structure

- `nix/`: Nix modules and configurations
- `.github/workflows/`: CI/CD configurations