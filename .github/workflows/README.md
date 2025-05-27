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

### 4. 🚀 `deploy.yaml`

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

## Workflow Artifacts

Both workflows generate artifacts that can be downloaded from the GitHub Actions UI:
- `code-quality-report.md`: Detailed code quality report
- `build-report-<os>.md`: Build and test results per platform
- `gitleaks-results.sarif`: Security scan results (if any issues found)

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
