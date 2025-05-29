# Automation Scripts

This directory contains scripts used in GitHub Actions workflows for task automation, testing, and system management.

## Available Scripts

### 1. Health Check Script (`health-check.sh`)
A comprehensive system health check script that verifies the system state after deployments.

### 2. System Rollback Script (`system-rollback.sh`)
Provides automated rollback functionality for NixOS and nix-darwin systems. See [ROLLBACK.md](./ROLLBACK.md) for detailed documentation.

### 3. Matrix Notification Script (`send-matrix-notification.sh`)
Sends notifications to a Matrix room.

## health-check.sh

A comprehensive system health check script designed to verify the system state after deployments.

### Features

- Verifies systemd service status
- Monitors system resource usage (CPU, memory, disk)
- Checks network connectivity and DNS resolution
- Verifies critical listening ports
- Provides color-coded output for better readability
- Includes troubleshooting recommendations
- Supports both interactive and non-interactive modes
- Configurable thresholds and settings

### Usage

```bash
# Run with sudo for complete system checks
sudo ./.github/scripts/health-check.sh

# Run with debug output
DEBUG=1 ./.github/scripts/health-check.sh

# Check only the exit code (useful for CI/CD)
./.github/scripts/health-check.sh > /dev/null
echo $?  # 0 if all checks passed, 1 if any check failed
```

### Exit Codes

- `0`: All checks passed successfully
- `1`: One or more checks failed
- `2`: Script was interrupted by user
- `3`: Missing required dependencies

### Integration with GitHub Actions

Example workflow integration:

```yaml
- name: Run System Health Check
  id: health_check
  run: |
    chmod +x ./.github/scripts/health-check.sh
    ./.github/scripts/health-check.sh
  continue-on-error: true  # Continue even if checks fail

- name: Handle Health Check Result
  if: steps.health_check.outcome == 'failure'
  run: |
    echo "Health check failed! Taking action..."
    # Add your failure handling logic here
```

### Configuration

You can customize the following aspects by modifying the script:

1. **Resource Thresholds** (in the script header):
   - `MEMORY_THRESHOLD`: Percentage of memory usage before warning
   - `DISK_THRESHOLD`: Percentage of disk usage before warning
   - `PORTS_TO_CHECK`: Array of ports to verify are listening

2. **Check Functions**:
   - `check_services()`: Verifies systemd services
   - `check_resources()`: Checks CPU, memory, and disk usage
   - `check_connectivity()`: Tests network and DNS
   - `check_ports()`: Verifies listening ports

### Requirements

- **Bash 4.0+**
- **Core System Commands**:
  - `systemctl` (for service management)
  - `journalctl` (for viewing logs)
  - `ping` (for network connectivity)
  - `nslookup` or `dig` (for DNS resolution)
  - `nc` or `netcat` (for port checking)
  - Standard GNU core utilities (awk, grep, etc.)

### Dependencies Installation

On Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y iputils-ping dnsutils netcat-openbsd
```

On RHEL/CentOS:
```bash
sudo yum install -y iputils bind-utils nmap-ncat
```

### Troubleshooting

#### Common Issues

1. **Permission Denied**
   - Run with sudo: `sudo ./health-check.sh`
   - Ensure the script is executable: `chmod +x health-check.sh`

2. **Command Not Found**
   - Install missing packages (see Dependencies Installation)
   - Check your PATH environment variable

3. **Incomplete Output**
   - Run with `bash -x` for debug output
   - Check system logs: `journalctl -xe`

#### Debugging

1. **Verbose Output**:
   ```bash
   DEBUG=1 ./health-check.sh
   ```

2. **Check System Logs**:
   ```bash
   journalctl -xe --no-pager | tail -n 50
   ```

3. **Test Individual Components**:
   ```bash
   # Test service status
   systemctl list-units --state=failed
   
   # Test disk space
   df -h
   
   # Test memory usage
   free -h
   
   # Test network connectivity
   ping -c 4 8.8.8.8
   nslookup google.com
   ```

### Security Considerations

- The script requires root privileges for complete functionality
- Review and customize the list of checked ports based on your security requirements
- The script includes error handling to prevent sensitive information leakage
- Consider setting appropriate file permissions: `chmod 750 health-check.sh`

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/health-check-improvements`
3. Commit your changes: `git commit -am 'Add some improvements'`
4. Push to the branch: `git push origin feature/health-check-improvements`
5. Submit a pull request

### License

[Specify your license here, e.g., MIT, GPL-3.0, etc.]
