# GitHub Workflows

This directory contains GitHub Actions workflows for the project.

## Available Workflows

### 🔍 `validate-flake.yaml`

**Purpose**: Basic validation of flake configuration and Nix code quality.

**When it runs**:
- On every push to the `main` branch
- On every pull request to `main`
- Manually triggered from the GitHub interface

**Tasks performed**:
1. Validates the flake structure
2. Verifies the flake evaluates correctly
3. Checks code formatting with `alejandra`
4. Runs `statix` linter
5. Looks for dead code with `deadnix`

### 🧹 `code-quality.yaml`

**Purpose**: In-depth code quality and security analysis.

**When it runs**:
- On every push to the `main` branch
- On every pull request to `main`
- Manually triggered from the GitHub interface

**Tasks performed**:
1. Security analysis with CodeQL
2. Dependency analysis and vulnerability checking
3. Code metrics calculation
4. Secret scanning with Gitleaks
5. Generates a comprehensive quality report

## How to Add a New Workflow

1. Create a new `.yaml` file in this directory
2. Use descriptive names for the workflow and steps
3. Include comments explaining the purpose of each step
4. Update this README.md to document the new workflow

## Naming Conventions

- Use infinitive verbs for step names
- Include relevant emojis for better readability
- Use `kebab-case` for file names
- Job names should be descriptive and start with a verb
