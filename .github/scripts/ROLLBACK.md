# System Rollback Script

## Overview

The `system-rollback.sh` script provides automated rollback functionality for NixOS and nix-darwin systems. It's designed to be used in CI/CD pipelines to automatically revert to a previous working state when deployments fail.

## Features

- Supports both NixOS and nix-darwin systems
- Dry-run mode for testing
- Configurable number of generations to keep
- Detailed logging and error reporting
- Safe rollback with pre-verification
- Automatic cleanup of old generations

## Prerequisites

- Nix package manager
- Systemd (for NixOS)
- Launchd (for nix-darwin)
- Sudo access (for nix-darwin rollbacks)

## Usage

```bash
./system-rollback.sh --target [nixos|darwin] [options]
```

### Options

- `--target SYSTEM`    Target system (nixos or darwin) - **required**
- `--dry-run`         Show what would be done without making changes
- `--max-generations NUM`  Maximum number of generations to keep (default: 5)
- `--help`            Show this help message

### Examples

1. **Basic usage (NixOS)**:
   ```bash
   ./system-rollback.sh --target nixos
   ```

2. **Dry run (nix-darwin)**:
   ```bash
   ./system-rollback.sh --target darwin --dry-run
   ```

3. **Keep more generations**:
   ```bash
   ./system-rollback.sh --target nixos --max-generations 10
   ```

## Exit Codes

- `0`: Rollback completed successfully
- `1`: Rollback failed
- `2`: Invalid arguments or environment

## Integration with CI/CD

Here's how to integrate the rollback script into your GitHub Actions workflow:

```yaml
- name: Deploy Configuration
  id: deploy
  run: |
    # Your deployment commands here
    # If any command fails, the step will fail

- name: Verify Deployment
  if: steps.deploy.outcome == 'failure'
  run: |
    echo "Deployment failed, initiating rollback..."
    chmod +x .github/scripts/system-rollback.sh
    ./.github/scripts/system-rollback.sh --target nixos || {
      echo "Rollback failed" >&2
      exit 1
    }
  continue-on-error: false
```

## Error Handling

The script includes comprehensive error handling:

1. Validates the target system
2. Verifies the existence of previous generations
3. Provides detailed error messages
4. Supports dry-run mode for testing

## Logging

- Informational messages are printed to stdout
- Error messages are printed to stderr
- Debug output is available by setting `DEBUG=1`
- All operations are logged with timestamps

## Security Considerations

- The script requires root privileges for nix-darwin rollbacks
- It's recommended to review the script before running with elevated privileges
- The script includes safety checks to prevent accidental data loss

## License

[Specify your license here, e.g., MIT, GPL-3.0, etc.]
