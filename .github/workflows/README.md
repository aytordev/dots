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

**Purpose**: Automatically deploys configuration changes to target systems.

**When it runs**:
- On push to `main` branch
- Manual trigger via workflow dispatch

**Key Features**:
- **Change Detection**:
  - Only deploys when configuration files change
  - Skips deployment if no relevant changes are detected
- **Deployment Process**:
  - Builds and applies configuration changes
  - Supports both NixOS and home-manager configurations
  - Detailed deployment reports
- **Status Tracking**:
  - GitHub Deployment API integration
  - Deployment status updates
  - Detailed deployment reports with change logs
- **Security**:
  - Minimal required permissions
  - Secure handling of secrets
  - Audit trail of all deployments

### 5. 🔔 `matrix-notify.yaml`

**Purpose**: Sends real-time notifications to Matrix about workflow status and results.

**When it runs**:
- After completion of any workflow in the pipeline
- Only on `success`, `failure`, or `cancelled` status
- Can be manually triggered for testing

**Key Features**:

- **Real-time Alerts**:
  - Instant notifications in your Matrix room
  - Clear status indicators with emojis for quick assessment
  - Different message formats for test and deployment workflows

- **Rich Notifications**:
  - Workflow name and status with appropriate emojis
  - Direct link to the workflow run
  - Commit hash and branch information
  - Trigger information (who initiated the workflow)

- **Smart Filtering**:
  - Only notifies on completed workflows
  - Skips skipped workflows
  - Separate handling for test and deployment notifications
  - Configurable notification triggers

- **Secure Integration**:
  - Uses encrypted secrets for authentication
  - Minimal required permissions
  - No sensitive data in notifications
  - Dedicated bot account recommended

**Setup Instructions**:

1. **Create a Matrix Bot Account**:
   - Create a new Matrix account for your bot (recommended)
   - Get an access token for the bot account

2. **Create a Matrix Room**:
   - Create a dedicated room for notifications
   - Invite the bot user to the room
   - Get the room ID (starts with `!`)

3. **Configure GitHub Secrets**:
   - `MATRIX_ROOM_ID`: The ID of your Matrix room (e.g., `!roomId:matrix.org`)
   - `MATRIX_ACCESS_TOKEN`: The access token for your bot account

4. **Manual Testing**:
   - Go to Actions → `matrix-notify.yaml`
   - Click "Run workflow"
   - Select workflow type: `test` or `deploy`
   - Add an optional test message
   - Click "Run workflow"

**Troubleshooting**:

- **No notifications received**:
  - Check if the workflow ran successfully
  - Verify the Matrix room ID and access token are correct
  - Ensure the bot has permission to send messages in the room
  - Check the workflow logs for any error messages

- **Malformed messages**:
  - Ensure proper escaping of special characters in messages
  - Check the JSON formatting in the script

**Customization**:

You can customize the notification format by modifying the message templates in the workflow file. The script supports both plain text and HTML formatting for rich notifications.

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
