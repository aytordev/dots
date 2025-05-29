#!/usr/bin/env bash
set -euo pipefail

# Debug mode - set DEBUG=1 to enable
if [ "${DEBUG:-0}" = "1" ]; then
    set -x
    export NIX_DEBUG=1
    export NIX_DEBUG_BUILD=1
    export NIX_DEBUG_BUILD_VERBOSE=1
fi

# =============================================================================
# Nix Configuration Integration Test Script
# 
# Description:
#   This script performs integration testing of Nix configurations, including
#   home-manager and nix-darwin configurations. It's designed to be used in CI/CD
#   pipelines to ensure configurations build correctly.
#
# Usage:
#   ./tests/integration.sh <platform>
#
# Exit Codes:
#   0 - All tests passed successfully
#   1 - One or more tests failed
#   2 - Invalid arguments or environment
#
# Dependencies:
#   - Nix package manager
#   - home-manager (optional)
#   - nix-darwin (optional)
# =============================================================================

# Color definitions for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0

# Print error message to stderr
error() {
    echo -e "${RED}❌ [ERROR]${NC} $1" >&2
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${YELLOW}💡 [DEBUG]${NC} Error occurred at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}" >&2
    fi
}

# Print success message
success() {
    echo -e "${GREEN}✅ [OK]${NC} $1"
}

# Print informational message
info() {
    echo -e "${YELLOW}ℹ️ [INFO]${NC} $1"
}

# Print section header
section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Check if required commands are available
check_dependencies() {
    local -a deps=("nix")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Required command not found: $dep"
            return 1
        fi
        
        # Print version info in debug mode
        if [ "${DEBUG:-0}" = "1" ]; then
            case "$dep" in
                nix)
                    nix --version
                    nix show-config | grep -E 'experimental-features|substituters|trusted-public-keys'
                    ;;
                *)
                    "$dep" --version || true
                    ;;
            esac
        fi
    done
    return 0
}

# Test home-manager configurations
test_home_configs() {
    section "Testing Home Manager Configurations"
    
    if ! nix eval --raw .#homeConfigurations &> /dev/null; then
        info "No home-manager configurations found, skipping..."
        return 0
    fi
    
    info "Found home-manager configurations"
    local configs
    configs=$(nix eval --raw .#homeConfigurations --apply 'x: builtins.attrNames x' | tr -d '[]\"' | tr ',' ' ')
    
    for config in $configs; do
        echo -e "\n🏠 Testing home configuration: ${BLUE}$config${NC}"
        if nix build .#homeConfigurations.\"$config\".activationPackage --print-build-logs; then
            success "Successfully built home configuration: $config"
            ((TESTS_PASSED++))
        else
            error "Failed to build home configuration: $config"
            ((TESTS_FAILED++))
        fi
    done
}

# Test nix-darwin configurations
test_darwin_configs() {
    section "Testing nix-darwin Configurations"
    
    if ! nix eval --raw .#darwinConfigurations &> /dev/null; then
        info "No nix-darwin configurations found, skipping..."
        return 0
    fi
    
    info "Found nix-darwin configurations"
    local configs
    configs=$(nix eval --raw .#darwinConfigurations --apply 'x: builtins.attrNames x' | tr -d '[]\"' | tr ',' ' ')
    
    for config in $configs; do
        echo -e "\n🍏 Testing darwin configuration: ${BLUE}$config${NC}"
        if nix build .#darwinConfigurations.\"$config\".system --print-build-logs; then
            success "Successfully built darwin configuration: $config"
            ((TESTS_PASSED++))
        else
            error "Failed to build darwin configuration: $config"
            ((TESTS_FAILED++))
        fi
    done
}

# Main function
main() {
    section "Starting Nix Configuration Integration Tests"
    
    # Check dependencies
    if ! check_dependencies; then
        exit 2
    fi
    
    # Run tests
    test_home_configs
    test_darwin_configs
    
    # Print summary
    section "Test Summary"
    echo -e "${GREEN}✅ $TESTS_PASSED tests passed${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}❌ $TESTS_FAILED tests failed${NC}"
        exit 1
    else
        success "All tests passed successfully!"
        exit 0
    fi
}

# Run main function
main "$@"
