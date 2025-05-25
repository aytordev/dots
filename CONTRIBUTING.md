# Contributing to dots

## 📝 Commit Message Convention

We follow a strict commit message convention that combines Conventional Commits and Gitmoji. This helps maintain a clear and consistent project history.

### Format

```
:emoji: type(scope): subject line (max 72 chars)

Detailed description (optional, can be multiple lines)
```

### Components

- **:emoji:** Represents the category of change (see table below)
- **type:** The type of change (required)
- **scope:** The module, folder, or component being changed (optional but recommended)
- **subject:** Brief description in present tense, no period at the end (max 72 characters)
- **description:** (Optional) Additional details about the changes, separated by a blank line

### Commit Types

| Emoji | Type       | Description |
|-------|------------|-------------|
| ✨ `:sparkles:` | `feat` | New feature |
| 🐛 `:bug:` | `fix` | Bug fix |
| 📝 `:memo:` | `docs` | Documentation changes |
| 🎨 `:art:` | `style` | Code style/formatting |
| ♻️ `:recycle:` | `refactor` | Code refactoring |
| 🧪 `:test_tube:` | `test` | Test changes |
| 🔧 `:wrench:` | `chore` | Build process or tooling changes |
| 👷 `:construction_worker:` | `ci` | CI/CD changes |
| 📦 `:package:` | `build` | Build system changes |
| 🚚 `:truck:` | `move` | File or directory moves |

### Rules

- Use **imperative present tense**: "add", "fix", "change" (not "added", "fixed", "changed")
- No capital letters or periods in the subject line
- Keep subject line under 72 characters
- Be specific about the scope of changes
- Make atomic commits (one logical change per commit)

### Examples

#### Simple commit (one line)
```
:sparkles: feat(home): add user configuration module
```

#### Commit with detailed description
```
:bug: fix(zsh): correct path in plugin wrapper

- Fix the path resolution for oh-my-zsh custom plugins
- Add error handling for missing plugin directories
- Update documentation to reflect changes

Fixes #123
```

#### Multi-line commit with scope
```
:recycle: refactor(system): separate platform-specific overlays

This refactoring separates the NixOS and Darwin specific overlays
into their own files for better maintainability. The changes include:

- Moved Darwin-specific packages to `overlays/darwin.nix`
- Moved NixOS-specific packages to `overlays/linux.nix`
- Updated `flake.nix` to import the appropriate overlay
```

#### Documentation update
```
:memo: docs(contributing): add commit message guidelines

Add comprehensive documentation about our commit message convention,
including examples and validation rules. This will help maintain
consistency across the project.

Closes #45
```

#### CI/CD changes
```
:construction_worker: ci: enable statix and deadnix in workflow

Add statix and deadnix checks to the GitHub Actions workflow to
enforce code quality standards and catch potential issues early.

- Add statix check for Nix best practices
- Add deadnix to detect unused Nix expressions
- Configure both to run on pull requests
```

## 🌿 Branching Strategy

We follow a simplified Git Flow approach with the following branch types:

- `main` - Stable, production-ready code
- `feat/*` - New features and enhancements
- `fix/*` - Bug fixes
- `docs/*` - Documentation improvements
- `chore/*` - Maintenance tasks and tooling

## 🛠️ Development Workflow

### 1. Starting a New Feature/Bugfix

```bash
# Make sure you're on the latest main branch
git checkout main
git pull

# Create and switch to a new feature branch
git checkout -b feat/feature-name  # or fix/issue-name
```

### 2. Making Changes

- Make small, atomic commits following our [commit message convention](#commit-message-convention)
- Keep your branch up to date with main
  ```bash
  git fetch origin
  git rebase origin/main
  ```
- Write tests when appropriate
- Update documentation as needed

### 3. Testing Your Changes

Before submitting your changes:

```bash
# Run the linters and tests
nix flake check

# For Nix-specific checks
nix run nixpkgs#statix check
deadnix .
```

### 4. Submitting Changes

1. Push your branch to the remote repository:
   ```bash
   git push -u origin feat/feature-name
   ```

2. Open a Pull Request (PR) against the `main` branch
   - Include a clear title and description
   - Reference any related issues
   - Request reviews from team members

3. Address any review feedback by pushing additional commits to your branch

### 5. After Approval

- Once approved, your PR will be squashed and merged into `main`
- Delete the feature branch after successful merge
- Update your local repository:
  ```bash
  git checkout main
  git pull
  git branch -d feat/feature-name
  ```

## 🤝 Code Review Guidelines

- Be constructive and respectful in reviews
- Focus on code quality, not personal preferences
- Suggest improvements rather than just pointing out issues
- Keep PRs focused and reasonably sized
- All PRs require at least one approval before merging

## 🔄 Keeping Your Fork Updated

If you're working with a fork:

```bash
# Add the original repository as 'upstream'
git remote add upstream https://github.com/original/repo.git

# Fetch the latest changes from upstream
git fetch upstream

# Update your main branch
git checkout main
git merge upstream/main
```

- Format Nix files with `nix fmt`
- Run linters with `nix flake check`
- Keep commits atomic and well-documented

## Code Style

### Naming Conventions

- **Variables and Functions**: Use `lowerCamelCase`  
  ```nix
  # Good
  myVariableName = "value";
  myFunctionName = param: param + 1;
  
  # Avoid
  my_variable_name = "value";
  my_function_name = param: param + 1;
  ```

- **File Names**: Use `kebab-case`  
  ```
  # Good
  my-module.nix
  user-configuration.nix
  
  # Avoid
  myModule.nix
  user_configuration.nix
  ```

### General Guidelines

- Keep lines under 100 characters
- Use 2 spaces for indentation in Nix files
- Include type annotations for function parameters in complex modules