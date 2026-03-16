# Contributing to cliproxy-qwen-monitor

Thank you for your interest in contributing! This guide explains how to get started.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork:
   ```bash
   git clone https://github.com/<your-user>/cliproxy-qwen-monitor.git
   cd cliproxy-qwen-monitor
   ```
3. **Create a branch** from `develop`:
   ```bash
   git checkout develop
   git checkout -b feature/my-feature
   ```

## Branching Model

We use Gitflow:

| Branch | Purpose |
|--------|---------|
| `main` | Stable releases only |
| `develop` | Integration branch for next release |
| `feature/*` | New features (branch from `develop`) |
| `fix/*` | Bug fixes (branch from `develop`) |
| `release/vX.Y.Z` | Release preparation (maintainers only) |
| `hotfix/*` | Urgent fixes for `main` (maintainers only) |

**All PRs target `develop`**, not `main`.

## Commit Format

```
<gitmoji> <type>(<scope>): <description>
```

### Gitmoji

Use real emoji from [gitmoji.dev](https://gitmoji.dev). Common ones:

| Emoji | Code | When to use |
|-------|------|-------------|
| ✨ | `:sparkles:` | New feature |
| 🐛 | `:bug:` | Bug fix |
| 📝 | `:memo:` | Documentation |
| ♻️ | `:recycle:` | Refactor |
| 🔧 | `:wrench:` | Configuration |
| ⬆️ | `:arrow_up:` | Upgrade dependency |
| 🎉 | `:tada:` | Initial commit |
| 🔒 | `:lock:` | Security fix |
| 🚀 | `:rocket:` | Deploy/release |
| 📦 | `:package:` | Add or update files |
| 📄 | `:page_facing_up:` | Add or update license |
| ✅ | `:white_check_mark:` | Add or update tests |
| 🔥 | `:fire:` | Remove code or files |
| 🚑 | `:ambulance:` | Critical hotfix |
| ⚡ | `:zap:` | Improve performance |
| 🎨 | `:art:` | Improve structure/format |
| ✏️ | `:pencil2:` | Fix typos |

### Additional Gitmoji for Releases

| Emoji | Code | When to use |
|-------|------|-------------|
| 🔖 | `:bookmark:` | Release tag |
| 📌 | `:pushpin:` | Pin dependencies |
| ⏪ | `:rewind:` | Revert changes |

### Types

`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`, `style`, `revert`

### Scopes (optional)

`monitor`, `scripts`, `docs`, `ci`, `config`

### Examples

```
✨ feat(monitor): add cooldown period between restarts
🐛 fix(scripts): handle grep returning empty string
📝 docs: add troubleshooting section to README
♻️ refactor(monitor): extract log parsing to function
📦 add(scripts): add test-qwen-direct.sh script
🔥 remove(scripts): remove deprecated test script
✅ test(monitor): add error pattern detection tests
🚑 fix(monitor): fix arithmetic syntax error in bash
⚡ perf(monitor): reduce check interval to 2 seconds
🎨 style(readme): improve ASCII art alignment
✏️ fix(docs): fix typo in CONTRIBUTING
🔖 release: v0.1.0
⏪ revert: revert "feat: add experimental feature"
```

## Script Structure

All bash scripts must follow this structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration variables
CHECK_INTERVAL=2
CONTAINER="cliproxyapi"

# Functions
log_msg() {
    echo "$1"
}

# Main logic
main() {
    log_msg "Starting..."
}

# Standalone guard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
```

### Required Practices

- Use `set -euo pipefail` at the top
- Use `local` keyword for function variables
- Use UPPER_CASE for global configuration
- Include standalone guard at the end
- Quote all variables: `"$var"`

### Syntax Validation

```bash
# Check syntax before committing
bash -n scripts/auto-restart-qwen.sh
```

## Code Review Checklist

Before submitting a PR, ensure:

### Code Quality
- [ ] Syntax check passed: `bash -n scripts/*.sh`
- [ ] Follows Bash conventions (`set -euo pipefail`, `local` keyword)
- [ ] Variables properly quoted
- [ ] Error handling with `|| variable=0` for grep commands

### Testing
- [ ] Tested with running CLIProxyAPI container
- [ ] Edge cases covered (container not found, docker compose errors)
- [ ] Monitor detects errors correctly

### Documentation
- [ ] README.md updated if behavior changed
- [ ] Commit messages follow format with gitmoji
- [ ] CHANGELOG.md updated with new entry

### Gitflow
- [ ] Branch created from `develop`
- [ ] Branch name follows convention: `feature/<description>` or `fix/<description>`
- [ ] PR targets `develop`, not `main`

## Pull Request Process

1. Branch from `develop`
2. Make your changes following the conventions above
3. Validate with syntax checks
4. Open a PR targeting `develop`
5. Fill out the PR template
6. Wait for review

## Releases

Releases are managed by maintainers only:

1. Create `release/vX.Y.Z` branch from `develop`
2. Update `CHANGELOG.md` with the new version
3. Open PR targeting `main`
4. Merge triggers the release process

## Guidelines

- Keep scripts focused and under 100 lines when possible
- Never log sensitive information (tokens, API keys)
- Test both success and error scenarios
- Add quickstart docs for new scripts
