# GitHub Workflows

This directory contains GitHub Actions workflows for the project's CI/CD pipeline.

## Available Workflows

### 1. 🔍 `validate-flake.yaml`

**Purpose**: Basic validation of flake configuration and Nix code quality.

**When it runs**:
- On every push to the `main` branch
- On every pull request to `main`
- Manual trigger via workflow dispatch

**Key Features**:
- **Flake Validation**:
  - Validates the flake structure
  - Verifies the flake evaluates correctly
- **Code Quality**:
  - Checks code formatting with `alejandra`
  - Runs `statix` linter for Nix best practices
  - Looks for dead code with `deadnix`
- **Fast Feedback**:
  - Quick execution time
  - Runs as the first line of defense

### 2. 🧹 `code-quality.yaml`

**Purpose**: In-depth code quality and security analysis.

**When it runs**:
- On push to `main` branch
- On pull requests targeting `main`
- Manual trigger via workflow dispatch

**Key Features**:
- **Security Analysis**:
  - Secret scanning with Gitleaks
  - Configuration: `.github/gitleaks.toml`
  - SARIF reports for GitHub code scanning
- **Code Quality**:
  - `statix` for Nix anti-pattern detection
  - Custom rules for Nix best practices
- **Dependency Analysis**:
  - Validates flake dependencies
  - Checks for outdated packages
- **Reporting**:
  - Generates detailed quality reports
  - Uploads results as workflow artifacts

### 3. 🏗️ `build-and-test.yaml`

**Purpose**: Validates that the configuration builds and works correctly across different platforms.

**When it runs**:
- On push to `main` branch
- On pull requests targeting `main`
- Manual trigger via workflow dispatch

**Platforms**:
- **Linux**: `x86_64-linux` (Ubuntu Latest)
- **macOS**: `x86_64-darwin` (macOS Latest)

**Key Features**:
- **Matrix Builds**:
  - Parallel execution across operating systems
  - Fail-fast disabled to see all platform-specific issues
- **Caching**:
  - Nix store caching for faster builds
  - Dependency caching between workflow runs
- **Testing**:
  - Integration tests in `tests/integration.sh`
  - Support for home-manager and nix-darwin configurations
  - Detailed build logs for debugging
- **Artifacts**:
  - Build reports for each platform
  - Test results and logs

### 4. 🚀 `deploy-nix-configs.yaml`

**Purpose**: Automatically deploys configuration changes to target systems with automated rollback on failure.

**When it runs**:
- On push to `main` branch
- Manual trigger via workflow dispatch

**Key Features**:
- **Change Detection**:
  - Only deploys when configuration files change (`.nix`, `.yaml`, `.sh`)
  - Skips deployment if no relevant changes are detected
  
- **Deployment Process**:
  - Automatically detects target system (NixOS or nix-darwin)
  - Builds and applies configuration changes
  - Supports both NixOS and nix-darwin configurations
  - Runs post-deployment health checks
  - Skips network and port checks in CI environment
  
- **Automated Rollback**:
  - Automatically triggers rollback workflow on deployment failure
  - Preserves system state by rolling back to last working configuration
  - Sends notifications for rollback events
  
- **Status Tracking**:
  - GitHub Deployment API integration
  - Detailed deployment reports with change logs
  - Deployment status updates
  
- **Security**:
  - Minimal required permissions
  - Secure handling of secrets
  - Audit trail of all deployments and rollbacks

### 5. 🔄 `rollback.yaml`

**Purpose**: Handles automated and manual rollbacks of system configurations.

**When it runs**:
- Automatically triggered by deployment workflow on failure
- Manual trigger via workflow dispatch
- On-demand rollback for maintenance

**Input Parameters**:
- `target`: Target system (`nixos` or `darwin`)
- `max_generations`: Maximum number of generations to keep (default: 5)

**Key Features**:
- **System-Agnostic**:
  - Works with both NixOS and nix-darwin
  - Automatically detects system type if not specified
  
- **Safe Rollback**:
  - Verifies target generation before rollback
  - Performs pre-rollback health checks for diagnostics
  - Preserves system integrity with pre-rollback checks
  - Dry-run mode for testing
  - CI-aware checks that skip network/port validation in CI environments
  
- **Cleanup**:
  - Automatically removes old generations
  - Configurable generation retention policy
  
- **Notifications**:
  - Sends status updates via Matrix
  - Detailed rollback reports
  - Error notifications for failed rollbacks

## Health Check System

The CI/CD pipeline includes a comprehensive health check system that runs during deployments and rollbacks.

### Health Check Features

- **Post-Deployment Verification**:
  - Runs after successful deployments
  - Verifies system health before considering deployment successful
  - Fails the deployment if critical issues are detected

- **Pre-Rollback Diagnostics**:
  - Runs before executing rollbacks
  - Provides diagnostic information about system state
  - Helps identify root causes of deployment failures

- **CI-Aware**:
  - Automatically detects CI environment
  - Skips network and port checks in CI
  - Provides appropriate logging for CI environments

### Customizing Health Checks

Health checks can be customized by modifying `.github/scripts/health-check.sh`. The script includes:

- Service status verification
- Resource usage monitoring
- Network connectivity tests
- Port availability checks

## Workflow Integration

### Deployment → Rollback Flow

1. Deployment workflow detects changes and starts deployment
2. If deployment fails:
   - Triggers rollback workflow
   - Passes target system information
   - Updates deployment status
3. Rollback workflow:
   - Identifies last working generation
   - Executes rollback
   - Cleans up old generations
   - Sends notifications

### Manual Rollback

To manually trigger a rollback:

1. Go to Actions → `rollback.yaml`
2. Click "Run workflow"
3. Select target system (nixos/darwin)
4. (Optional) Adjust max generations
5. Click "Run workflow"
  - Secure handling of secrets
  - Audit trail of all deployments

### 5. 🔔 `matrix-notify.yaml`

**Purpose**: Sends real-time notifications to Matrix about workflow status and results with clean, well-formatted messages.

**When it runs**:
- After completion of any workflow in the pipeline
- Only on `success`, `failure`, or `cancelled` status
- Can be manually triggered for testing

**Key Features**:

- **Beautifully Formatted Notifications**:
  - Clean, professional message formatting
  - Proper spacing and line breaks
  - Monospace font for better readability
  - Emoji indicators for quick status assessment

- **Rich Content**:
  - Workflow name and status with appropriate emojis
  - Direct link to the workflow run
  - Commit hash and branch information
  - Trigger information (who initiated the workflow)

- **Smart Filtering**:
  - Only notifies on completed workflows
  - Skips skipped workflows
  - Separate handling for test and deployment notifications
  - Configurable notification triggers

- **Secure & Reliable**:
  - Uses encrypted secrets for authentication
  - Minimal required permissions
  - No sensitive data in notifications
  - Dedicated bot account recommended
  - Proper error handling and logging

**Setup Instructions**:

1. **Create a Matrix Bot Account**:
   - Create a new Matrix account for your bot (recommended)
   - Get an access token for the bot account
   - Example: `/devtools` → `Access Token` → `Add a new access token`

2. **Create a Matrix Room**:
   - Create a dedicated room for notifications
   - Invite the bot user to the room
   - Get the room ID (starts with `!`)
   - Example: `!qDnvhRpIkIqZJReLfV:matrix.org`

3. **Configure GitHub Secrets**:
   - `MATRIX_ROOM_ID`: The ID of your Matrix room
   - `MATRIX_ACCESS_TOKEN`: The access token for your bot account
   - `MATRIX_HOMESERVER`: (Optional) Custom Matrix homeserver URL (defaults to `https://matrix.org`)

4. **Manual Testing**:
   - Go to Actions → `matrix-notify.yaml`
   - Click "Run workflow"
   - Select workflow type: `test` or `deploy`
   - Add an optional test message
   - Click "Run workflow"

   Or run locally:
   ```bash
   export MATRIX_ROOM_ID="!your-room-id:matrix.org"
   export MATRIX_ACCESS_TOKEN="your-access-token"
   export MATRIX_MESSAGE=$'🔔 **Test Notification**\n\nThis is a test message\nWith multiple lines\n\nAnd a blank line too'
   ./.github/scripts/send-matrix-notification.sh
   ```

**Troubleshooting**:

- **Deployment/Rollback Issues**:
  - Check workflow logs for specific error messages
  - Verify Nix store has enough disk space
  - Ensure proper permissions for Nix operations
  - Check network connectivity to GitHub and Nix caches

- **Rollback Not Triggering**:
  - Verify the deployment workflow has `actions: write` permission
  - Check if the rollback workflow is enabled
  - Ensure the target system is correctly detected

- **Matrix Notifications**:
  - Check if the workflow ran successfully
  - Verify the Matrix room ID and access token are correct
  - Ensure the bot has permission to send messages in the room
  - Check the workflow logs for any error messages
  - Verify the Matrix homeserver is accessible

- **Message formatting issues**:
  - Ensure proper line breaks in the message
  - Check for special characters that might need escaping
  - Verify the JSON formatting in the script

- **Authentication errors**:
  - Verify the access token is valid and not expired
  - Check if the bot has the necessary permissions in the room
  - Ensure the room ID is correctly formatted

**Message Format**:

Notifications follow this format:
```
🔔 **Workflow Name**

📦 Repository: owner/repo
✅ Status: success/failure
🔗 [View Run](workflow-run-url)

Commit: `abc123`
Branch: `main`
Triggered by: username
```

For deployment notifications, additional details about the deployment status are included.

**Customization**:

You can customize the notification format by modifying the message templates in the workflow file. The script supports both plain text and HTML formatting for rich notifications.

**Rate Limiting**:

- The Matrix API has rate limits to prevent abuse
- The default rate limit is approximately 1 message per second per user
- For high-volume notifications, consider:
  - Batching multiple messages
  - Adding delays between notifications
  - Using a dedicated high-limits application service if needed

**Security Notes**:

- Never commit the Matrix access token to version control
- Use a dedicated bot account with minimal permissions
- Regularly rotate the access token
- Keep the notification room private
- Review the notification content to ensure no sensitive information is leaked

## Workflow Artifacts

Workflows generate various artifacts that can be downloaded from the GitHub Actions UI:
- `code-quality-report.md`: Detailed code quality report
- `build-report-<os>.md`: Build and test results per platform
- `gitleaks-results.sarif`: Security scan results (if any issues found)
- Matrix notifications for real-time workflow status updates

## Matrix Notification Script

The notification system is powered by a dedicated script located at `.github/scripts/send-matrix-notification.sh`. This script handles the communication with the Matrix API and provides several features:

### Features

- **Robust Error Handling**: Proper error messages and exit codes
- **JSON Escaping**: Automatically handles special characters in messages
- **Flexible Input**: Accepts input from command line arguments or environment variables
- **HTML Formatting**: Supports rich text formatting in Matrix messages
- **Dependency Management**: Automatically installs required dependencies

### Script Usage

```bash
# Using command line arguments
./send-matrix-notification.sh "!room:matrix.org" "your_access_token" "Your message here"

# Using environment variables
export MATRIX_ROOM_ID="!room:matrix.org"
export MATRIX_ACCESS_TOKEN="your_access_token"
export MATRIX_MESSAGE="Your message here"
./send-matrix-notification.sh

# Show help
./send-matrix-notification.sh --help
```

### Exit Codes

- `0`: Success
- `1`: Missing dependencies (jq)
- `2`: Missing required arguments
- `3`: Failed to create JSON payload
- `4`: Failed to send message

## How to Add a New Workflow

1. Create a new `.yaml` file in this directory
2. Use descriptive names for the workflow and steps
3. Include comments explaining the purpose of each step
4. Document the workflow in this README.md file

## Naming Conventions

- **File Names**: Use `kebab-case` (e.g., `build-and-test.yaml`)
- **Job Names**: Start with a verb in present tense (e.g., `build`, `test`, `deploy`)
- **Step Names**: Use action verbs and include relevant emojis for better readability
- **Environment Variables**: Use `SCREAMING_SNAKE_CASE`
- **Secrets**: Store sensitive values in GitHub Secrets

## Best Practices

1. **Idempotency**: Workflows should be idempotent - running them multiple times should be safe
2. **Timeouts**: Set appropriate timeouts for jobs to prevent hanging workflows
3. **Dependencies**: Use `needs` to define job dependencies when order matters
4. **Conditional Execution**: Use `if` conditions to skip unnecessary jobs
5. **Artifacts**: Upload build outputs and reports as artifacts for debugging
6. **Caching**: Cache dependencies and build outputs to speed up workflows
7. **Failure Handling**: Use `continue-on-error` for non-critical steps
8. **Notifications**: Configure status notifications for workflow results
