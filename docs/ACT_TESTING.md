# Local GitHub Actions Testing with Act

This project supports testing GitHub Actions workflows locally using [act](https://github.com/nektos/act).

## Prerequisites

### Install Act

**macOS (Homebrew):**
```bash
brew install act
```

**Linux:**
```bash
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Windows (Chocolatey):**
```powershell
choco install act-cli
```

**Manual Installation:**
Download from the [releases page](https://github.com/nektos/act/releases).

### Install Docker

Act requires Docker to run the GitHub Actions containers. Make sure Docker is installed and running.

## Usage

### Setup Act Test Events

First, set up the test events for act:

```bash
make act-setup
```

This creates:
- `.github/events/` directory with test event files

**Note:** This project assumes you have a global `~/.actrc` configuration file. If you don't have one, create it with your preferred runner images and settings.

### Available Commands

```bash
# List all available workflows
make act-list

# Test the CI workflow (runs on push)
make act-ci

# Test the release workflow (runs on tag push)
make act-release

# Show help with all available commands
make help
```

### Manual Act Commands

You can also run act directly:

```bash
# List all workflows
act --list

# Run CI workflow
act push

# Run release workflow with tag event
act push -e .github/events/tag-push.json

# Run specific job
act push -j test

# Dry run (don't actually run, just show what would happen)
act push --dry-run

# Use different runner image
act push -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

## Configuration

### Global .actrc File

This project uses your global `~/.actrc` configuration file. If you don't have one, create it at `~/.actrc` with content like:

```
# Use GitHub-compatible runner images
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04

# Set default platform
--platform ubuntu-latest=catthehacker/ubuntu:act-latest

# Enable verbose output
--verbose
```

### Event Files

Test event files are stored in `.github/events/`:
- `tag-push.json` - Simulates a tag push event for release workflow

## Troubleshooting

### Common Issues

1. **Docker not running**: Make sure Docker is installed and running
2. **Permission issues**: On Linux, you might need to add your user to the docker group
3. **Slow first run**: Act downloads runner images on first use, which can be slow

### Runner Images

Act uses different runner images than GitHub Actions. The configuration uses `catthehacker/ubuntu:act-*` images which are optimized for act and more compatible.

### Secrets and Environment Variables

For workflows that require secrets:

```bash
# Create a .secrets file (don't commit this!)
echo "GITHUB_TOKEN=your_token_here" > .secrets

# Run with secrets
act push --secret-file .secrets
```

## Limitations

- Some GitHub Actions features may not work exactly the same
- Network access and external services work differently
- File permissions might behave differently
- Some GitHub-specific contexts may not be available

## Benefits

- Test workflows before pushing to GitHub
- Faster iteration on CI/CD changes
- Debug workflow issues locally
- Validate workflow syntax and logic

## Examples

### Test the Release Workflow

```bash
# Setup act if not done already
make act-setup

# Test release workflow
make act-release
```

This will simulate pushing a tag and run through the entire release process locally, including:
- Building the plugin
- Running tests
- Creating release artifacts
- Generating release notes

### Test CI Changes

```bash
# Test CI workflow after making changes
make act-ci
```

This runs the CI workflow that normally triggers on push events.
