#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# System Health Check Script
# 
# Description:
#   This script performs comprehensive health checks on a Linux system, including
#   service status, resource usage, and network connectivity. It's designed to be
#   used in CI/CD pipelines or as a standalone monitoring tool.
#
# Exit Codes:
#   0 - All checks passed successfully
#   1 - One or more checks failed
#   2 - Script was interrupted by user
#   3 - Missing required dependencies
#
# Dependencies:
#   - systemd (for service management)
#   - coreutils (basic shell commands)
#   - iputils-ping (for ping)
#   - dnsutils (for nslookup)
#   - netcat-openbsd (for port checking)
# =============================================================================

# Color definitions for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Thresholds (customize as needed)
readonly MEMORY_THRESHOLD=90  # Percentage
readonly DISK_THRESHOLD=90    # Percentage
readonly PORTS_TO_CHECK=(22 80 443)  # Common ports to verify

# Global variables
declare -a FAILED_CHECKS=()
EXIT_CODE=0

# =============================================================================
# Utility Functions
# =============================================================================

# Print error message to stderr
# Usage: error "message"
error() {
    echo -e "${RED}❌ [ERROR]${NC} $1" >&2
}

# Print success message
# Usage: success "message"
success() {
    echo -e "${GREEN}✅ [OK]${NC} $1"
}

# Print informational message
# Usage: info "message"
info() {
    echo -e "${YELLOW}ℹ️ [INFO]${NC} $1"
}

# Print debug message (only shown when DEBUG=1)
# Usage: debug "message"
debug() {
    if [ "${DEBUG:-0}" -eq 1 ]; then
        echo -e "${BLUE}🐛 [DEBUG]${NC} $1"
    fi
}

# Función para mostrar mensajes de error
error() {
    echo -e "${RED}❌ [ERROR]${NC} $1" >&2
}

# Función para mostrar mensajes de éxito
success() {
    echo -e "${GREEN}✅ [OK]${NC} $1"
}

# Función para mostrar información
info() {
    echo -e "${YELLOW}ℹ️ [INFO]${NC} $1"
}

# =============================================================================
# Check Functions
# =============================================================================

# Check systemd services status
# Returns:
#   0 if all services are running
#   1 if any service has failed
check_services() {
    local header="${BLUE}=== Checking System Services ===${NC}"
    echo -e "\n$header"
    
    info "Checking systemd services..."
    
    local failed_services
    failed_services=$(systemctl list-units --state=failed --no-legend --no-pager | awk '{print $1}' 2>/dev/null || true)
    
    if [ -n "$failed_services" ]; then
        error "Failed services detected:"
        while IFS= read -r service; do
            if [ -z "$service" ]; then continue; fi
            echo -e "\n  - ${RED}$service${NC}"
            
            # Get service status
            local status
            status=$(systemctl is-active "$service" 2>/dev/null || echo 'inactive')
            echo "    Status: $status"
            
            # Get service description
            local description
            description=$(systemctl show -p Description --value "$service" 2>/dev/null || echo 'No description')
            [ -n "$description" ] && echo "    Description: $description"
            
            # Show recent logs
            echo "    Recent logs:"
            if journalctl -u "$service" --no-pager -n 3 --no-hostname 2>/dev/null; then
                : # Logs shown
            else
                echo "      No logs available or insufficient permissions"
            fi
        done <<< "$failed_services"
        
        FAILED_CHECKS+=("services")
        return 1
    fi
    
    success "All systemd services are running"
    return 0
}

# Check system resources (CPU, memory, disk)
# Returns:
#   0 if resources are within thresholds
#   1 if any resource exceeds thresholds
check_resources() {
    local header="${BLUE}=== Checking System Resources ===${NC}"
    echo -e "\n$header"
    
    info "Checking system resources..."
    local resource_ok=true
    
    # Check memory usage
    local mem_usage
    if mem_usage=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100.0}' 2>/dev/null); then
        if [ "$mem_usage" -gt "$MEMORY_THRESHOLD" ]; then
            error "High memory usage: ${mem_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
            resource_ok=false
        else
            success "Memory usage: ${mem_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        fi
    else
        error "Failed to check memory usage"
        resource_ok=false
    fi
    
    # Check disk usage
    local disk_usage
    if disk_usage=$(df -h / | awk 'NR==2 {gsub(/%/,"",$5); print $5}' 2>/dev/null); then
        if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
            error "High disk usage: ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
            resource_ok=false
        else
            success "Disk usage: ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
        fi
    else
        error "Failed to check disk usage"
        resource_ok=false
    fi
    
    # Check load average
    local load_avg
    load_avg=$(awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null || echo "unknown")
    info "System load average: $load_avg"
    
    if [ "$resource_ok" = false ]; then
        FAILED_CHECKS+=("resources")
        return 1
    fi
    
    return 0
}

# Check network connectivity and DNS resolution
# Returns:
#   0 if network connectivity is working
#   1 if there are connectivity issues
check_connectivity() {
    local header="${BLUE}=== Checking Network Connectivity ===${NC}"
    echo -e "\n$header"
    
    info "Checking network connectivity..."
    local connectivity_ok=true
    
    # Test Internet connectivity
    info "Testing Internet connectivity..."
    if ! ping -c 2 -W 2 8.8.8.8 &>/dev/null; then
        error "Cannot reach the Internet (ping to 8.8.8.8 failed)"
        connectivity_ok=false
    else
        success "Internet connectivity is working"
    fi
    
    # Test DNS resolution
    info "Testing DNS resolution..."
    if ! nslookup google.com &>/dev/null; then
        error "DNS resolution failed (could not resolve google.com)"
        connectivity_ok=false
    else
        success "DNS resolution is working"
    fi
    
    # Check default gateway
    local gateway
    if gateway=$(ip route | awk '/default/ {print $3}' | head -1); then
        info "Default gateway: $gateway"
        if ! ping -c 1 -W 1 "$gateway" &>/dev/null; then
            error "Cannot ping default gateway: $gateway"
            connectivity_ok=false
        fi
    else
        error "Could not determine default gateway"
        connectivity_ok=false
    fi
    
    if [ "$connectivity_ok" = false ]; then
        FAILED_CHECKS+=("connectivity")
        return 1
    fi
    
    return 0
}

# Check if critical ports are listening
# Returns:
#   0 if all specified ports are listening
#   1 if any port is not listening
check_ports() {
    local header="${BLUE}=== Checking Critical Ports ===${NC}"
    echo -e "\n$header"
    
    info "Checking if critical ports are listening..."
    local all_ok=true
    
    # Check if netcat is available
    if ! command -v nc &>/dev/null; then
        warning "netcat (nc) not found, skipping port checks"
        return 0
    fi
    
    for port in "${PORTS_TO_CHECK[@]}"; do
        if nc -z localhost "$port" &>/dev/null; then
            success "Port $port is listening"
        else
            error "Port $port is not listening"
            all_ok=false
        fi
    done
    
    if [ "$all_ok" = false ]; then
        FAILED_CHECKS+=("ports")
        return 1
    fi
    
    return 0
}

# =============================================================================
# Main Function
# =============================================================================

# Main execution function
# Handles script execution flow and error handling
main() {
    local start_time
    start_time=$(date +%s)
    
    # Handle script interruption
    trap 'handle_interrupt' INT TERM
    
    # Print header
    echo -e "\n${BLUE}===== System Health Check =====${NC}"
    echo -e "Started at: $(date)\n"
    
    # Check for root privileges
    if [ "$(id -u)" -ne 0 ]; then
        warning "Some checks require root privileges. Running with limited functionality."
    fi
    
    # Check dependencies
    check_dependencies || return $?
    
    # Execute all health checks
    local checks=(
        "check_services"
        "check_resources"
        "check_connectivity"
        "check_ports"
    )
    
    for check in "${checks[@]}"; do
        if ! "$check"; then
            EXIT_CODE=1
        fi
    done
    
    # Print summary
    print_summary
    
    # Calculate execution time
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    info "Health check completed in ${duration} seconds"
    
    return $EXIT_CODE
}

# Check for required dependencies
check_dependencies() {
    local deps=("systemctl" "awk" "grep" "ping" "nslookup")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        return 3
    fi
    
    return 0
}

# Handle script interruption
handle_interrupt() {
    echo -e "\n${YELLOW}⚠️ Script interrupted by user${NC}"
    cleanup
    exit 2
}

# Cleanup function (runs on exit)
cleanup() {
    # Add any cleanup tasks here
    debug "Cleaning up..."
}

# Print summary of checks
print_summary() {
    local header="${BLUE}=== Check Summary ===${NC}"
    echo -e "\n$header"
    
    if [ $EXIT_CODE -eq 0 ]; then
        success "✅ All health checks passed successfully"
    else
        error "❌ Some health checks failed"
        echo -e "\n${YELLOW}🔧 Recommended Actions:${NC}"
        
        for check in "${FAILED_CHECKS[@]}"; do
            case $check in
                "services")
                    echo "- Check failed services: systemctl list-units --state=failed"
                    echo "  View service logs: journalctl -u <service> -n 50"
                    ;;
                "resources")
                    echo "- Check system resources:"
                    echo "  Memory: free -h"
                    echo "  Disk: df -h"
                    echo "  CPU: top -bn1 | head -15"
                    ;;
                "connectivity")
                    echo "- Check network configuration:"
                    echo "  IP addresses: ip a"
                    echo "  Routing: ip route"
                    echo "  DNS: cat /etc/resolv.conf"
                    ;;
                "ports")
                    echo "- Check listening ports: ss -tulpn"
                    echo "  Or use: netstat -tulpn"
                    ;;
            esac
done

        # Add general troubleshooting commands
        echo -e "\n${YELLOW}📋 General troubleshooting commands:${NC}"
        echo "- System logs: journalctl -xe"
        echo "- Recent logins: last -n 10"
        echo "- System uptime: uptime"
    fi
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Only execute main if script is run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    # Run main function and capture exit code
    if main "$@"; then
        exit 0
    else
        exit $?
    fi
fi
