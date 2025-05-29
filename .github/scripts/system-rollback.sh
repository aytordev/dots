#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# System Rollback Script for NixOS/nix-darwin
# 
# Description:
#   This script provides rollback functionality for NixOS and nix-darwin systems.
#   It's designed to be used in CI/CD pipelines to automatically rollback to a
#   previous working state when deployments fail.
#
# Usage:
#   ./system-rollback.sh --target [nixos|darwin] [--dry-run] [--max-generations NUM]
#
# Exit Codes:
#   0 - Rollback completed successfully
#   1 - Rollback failed
#   2 - Invalid arguments or environment
#
# Dependencies:
#   - Nix package manager
#   - systemd (for NixOS)
#   - launchd (for nix-darwin)
# =============================================================================

# Color definitions for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default values
TARGET_SYSTEM=""
DRY_RUN=false
MAX_GENERATIONS=5
CURRENT_GENERATION=""
ROLLBACK_GENERATION=""
ROLLBACK_SUCCESS=false

# Print error message to stderr
error() {
    echo -e "${RED}❌ [ROLLBACK ERROR]${NC} $1" >&2
}

# Print success message
success() {
    echo -e "${GREEN}✅ [ROLLBACK SUCCESS]${NC} $1"
}

# Print informational message
info() {
    echo -e "${YELLOW}ℹ️ [ROLLBACK INFO]${NC} $1"
}

# Print debug message (only when DEBUG=1)
debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${BLUE}🐛 [ROLLBACK DEBUG]${NC} $1"
    fi
}

# Print usage information
usage() {
    echo "Usage: $0 --target [nixos|darwin] [options]"
    echo "Options:"
    echo "  --target SYSTEM    Target system (nixos or darwin)"
    echo "  --dry-run         Show what would be done without making changes"
    echo "  --max-generations NUM  Maximum number of generations to keep (default: 5)"
    echo "  --help            Show this help message"
    exit 2
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target)
                TARGET_SYSTEM="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --max-generations)
                MAX_GENERATIONS="$2"
                shift 2
                ;;
            --help)
                usage
                ;;
            *)
                error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate target system
    if [[ "$TARGET_SYSTEM" != "nixos" && "$TARGET_SYSTEM" != "darwin" ]]; then
        error "Invalid target system: $TARGET_SYSTEM. Must be 'nixos' or 'darwin'"
        usage
    fi
}

# Get current system generation
get_current_generation() {
    if [[ "$TARGET_SYSTEM" == "nixos" ]]; then
        CURRENT_GENERATION=$(nix-env -p /nix/var/nix/profiles/system --list-generations | grep "current" | awk '{print $1}')
    else # darwin
        CURRENT_GENERATION=$(nix-env -p /nix/var/nix/profiles/system-profiles/system --list-generations | grep "current" | awk '{print $1}')
    fi
    
    if [ -z "$CURRENT_GENERATION" ]; then
        error "Failed to determine current generation"
        return 1
    fi
    
    info "Current generation: $CURRENT_GENERATION"
}

# Get the previous generation to rollback to
get_rollback_generation() {
    if [[ "$TARGET_SYSTEM" == "nixos" ]]; then
        ROLLBACK_GENERATION=$(nix-env -p /nix/var/nix/profiles/system --list-generations | \
            grep -v "current" | tail -n 2 | head -n 1 | awk '{print $1}')
    else # darwin
        ROLLBACK_GENERATION=$(nix-env -p /nix/var/nix/profiles/system-profiles/system --list-generations | \
            grep -v "current" | tail -n 2 | head -n 1 | awk '{print $1}')
    fi
    
    if [ -z "$ROLLBACK_GENERATION" ]; then
        error "No previous generation found for rollback"
        return 1
    fi
    
    info "Rolling back to generation: $ROLLBACK_GENERATION"
}

# Perform the rollback
perform_rollback() {
    local generation=$1
    
    info "Initiating rollback to generation $generation..."
    
    if [ "$DRY_RUN" = true ]; then
        info "[DRY RUN] Would rollback to generation $generation"
        return 0
    fi
    
    if [[ "$TARGET_SYSTEM" == "nixos" ]]; then
        # For NixOS
        if ! nixos-rollback --use-generation "$generation"; then
            error "Failed to execute nixos-rollback"
            return 1
        fi
    else
        # For nix-darwin
        if ! sudo -i nix-env -p /nix/var/nix/profiles/system-profiles/system --switch-generation "$generation" || \
           ! /nix/var/nix/profiles/system-profiles/system/activate; then
            error "Failed to switch to generation $generation"
            return 1
        fi
    fi
    
    success "Successfully rolled back to generation $generation"
    ROLLBACK_SUCCESS=true
}

# Clean up old generations
cleanup_old_generations() {
    info "Cleaning up old generations (keeping last $MAX_GENERATIONS)..."
    
    if [ "$DRY_RUN" = true ]; then
        info "[DRY RUN] Would clean up old generations, keeping last $MAX_GENERATIONS"
        return 0
    fi
    
    if [[ "$TARGET_SYSTEM" == "nixos" ]]; then
        nix-env -p /nix/var/nix/profiles/system --delete-generations "+$MAX_GENERATIONS"
    else
        nix-env -p /nix/var/nix/profiles/system-profiles/system --delete-generations "+$MAX_GENERATIONS"
    fi
    
    if [ $? -eq 0 ]; then
        success "Successfully cleaned up old generations"
    else
        error "Failed to clean up old generations"
        return 1
    fi
}

# Main function
main() {
    parse_args "$@"
    
    info "Starting rollback procedure for $TARGET_SYSTEM"
    
    # Get current generation
    if ! get_current_generation; then
        error "Failed to get current generation"
        exit 1
    fi
    
    # Get rollback generation
    if ! get_rollback_generation; then
        error "Failed to determine rollback generation"
        exit 1
    fi
    
    # Check if we have a valid rollback target
    if [ "$CURRENT_GENERATION" -eq "$ROLLBACK_GENERATION" ]; then
        info "Current generation is the same as rollback target, nothing to do"
        exit 0
    fi
    
    # Perform the rollback
    if ! perform_rollback "$ROLLBACK_GENERATION"; then
        error "Rollback failed"
        exit 1
    fi
    
    # Clean up old generations if rollback was successful
    if [ "$ROLLBACK_SUCCESS" = true ]; then
        cleanup_old_generations || true
    fi
    
    exit 0
}

# Run main function
main "$@"
