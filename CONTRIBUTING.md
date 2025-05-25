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

## Development Workflow

1. Create a new branch for your changes
2. Make your changes following the commit convention
3. Run `nix flake check` to ensure everything works
4. Open a pull request with a clear description of your changes

- Format Nix files with `nix fmt`
- Run linters with `nix flake check`
- Keep commits atomic and well-documented

## Code Style

- Use `lowerCamelCase` for variable names
- Use `snake_case` for file names
- Keep lines under 100 characters