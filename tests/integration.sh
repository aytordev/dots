#!/usr/bin/env bash
set -euo pipefail

# Integration test script for Nix configurations
# This script will be called by the CI workflow

echo "🚀 Starting integration tests for platform: $1"

# Check if home-manager is available
if nix eval --raw .#homeConfigurations 2>/dev/null; then
    echo "✅ home-manager configurations found"
    
    # Test building all home configurations
    for config in $(nix eval --raw .#homeConfigurations --apply 'x: builtins.attrNames x' | tr -d '[]\"' | tr ',' ' '); do
        echo "🏠 Building home configuration: $config"
        nix build .#homeConfigurations.\"$config\".activationPackage --print-build-logs
    done
else
    echo "ℹ️ No home-manager configurations found, skipping..."
fi

# Check if nix-darwin is available
if nix eval --raw .#darwinConfigurations 2>/dev/null; then
    echo "✅ nix-darwin configurations found"
    
    # Test building all darwin configurations
    for config in $(nix eval --raw .#darwinConfigurations --apply 'x: builtins.attrNames x' | tr -d '[]\"' | tr ',' ' '); do
        echo "🍏 Building darwin configuration: $config"
        nix build .#darwinConfigurations.\"$config\".system --print-build-logs
    done
else
    echo "ℹ️ No nix-darwin configurations found, skipping..."
fi

echo "✨ All integration tests completed successfully!"
