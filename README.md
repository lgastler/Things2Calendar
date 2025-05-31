# Things2Calendar

[![Release](https://img.shields.io/github/v/release/lennartgastler/Things2Calendar)](https://gith**Manual:**
```bash
# Generate version bump and changelog
npx @changesets/cli version

# Review changes, then commit and push
git add -A && git commit -m "chore: release packages"
git push origin main

# Create tag to trigger release build
git tag v$(grep "^## " CHANGELOG.md | head -1 | sed 's/## //')
git push origin --tags
```tgastler/Things2Calendar/releases)

A Swift command-line utility to sync Things todos as time blocks to your calendar.

## Features

- 🔄 Sync Things todos as time blocks to any calendar
- 📅 Automatic calendar event creation
- 🏷️ Support for different durations provided by Things tags
- 🔗 Direct linking from the calendar back to Things tasks
- ⚡ Fast CLI with short `t2c` alias
- 🛡️ Proper macOS calendar permissions handling

## Installation

### Homebrew (Recommended)

```bash
brew install lennartgastler/tap/things2calendar
```

### Manual Installation

Download the latest release from [GitHub Releases](https://github.com/lennartgastler/Things2Calendar/releases):

```bash
# Download and install
curl -L https://github.com/lennartgastler/Things2Calendar/releases/latest/download/Things2Calendar-*-macos.tar.gz | tar xz
sudo mv Things2Calendar /usr/local/bin/
sudo mv t2c /usr/local/bin/
```

## Usage

### List Available Calendars

```bash
Things2Calendar calendars
# or using the short alias:
t2c calendars
```

### Sync Things Time Blocks to Calendar

```bash
Things2Calendar sync --calendar-identifier "YOUR_CALENDAR_ID"
# or using the short alias:
t2c sync --calendar-identifier "YOUR_CALENDAR_ID"
```

### Get Help

```bash
Things2Calendar --help
t2c --help
Things2Calendar --version
```

## Requirements

- macOS 14.0 or later
- Calendar access permissions (granted on first run)
- Things app with time blocks configured

## Development

### Local Development

```bash
git clone https://github.com/lennartgastler/Things2Calendar.git
cd Things2Calendar

# Build debug version
swift build

# Build release version
swift build -c release

# Run tests
swift test

# Quick test
.build/debug/Things2Calendar calendars

# Install globally
sudo cp .build/release/Things2Calendar /usr/local/bin/
sudo ln -sf /usr/local/bin/Things2Calendar /usr/local/bin/t2c
```

### Release Process with Changesets

This project uses [Changesets](https://github.com/changesets/changesets) for structured version management and changelog generation.

#### For Each Change

When you make any changes:

```bash
# Add a changeset describing your change
npx @changesets/cli add

# Commit your changes WITH the changeset
git add -A && git commit -m "feat: your feature description"
git push origin feature-branch
```

#### Creating Releases

**Automated (Recommended):**
1. Merge your PR to `main` 
2. Changesets will automatically create a "Version Packages" PR
3. Review and merge the Version Packages PR
4. Release is automatically built and published! 🚀

**Manual:**
```bash
# Generate version bump and changelog
npm run release:version

# Review changes, then commit and push
git add -A && git commit -m "chore: release packages"
git push origin main

# Create tag to trigger release build
git tag v$(grep "^## " CHANGELOG.md | head -1 | sed 's/## //')
git push origin --tags
```

#### What Happens Automatically

- 📝 **Changesets** collect all changes since last release
- � **Semantic versioning** based on changeset types
- � **Changelog generation** with GitHub links
- � **Version sync** across all files
- � **Build and sign** release binary
- 🚀 **Publish** to GitHub Releases

#### Changeset Types

- `major`: Breaking changes (1.0.0 → 2.0.0)
- `minor`: New features (1.0.0 → 1.1.0)  
- `patch`: Bug fixes (1.0.0 → 1.0.1)

See [`docs/CHANGESETS.md`](docs/CHANGESETS.md) for detailed workflow documentation.

### Development Commands

Run `make help` to see all available commands.

## Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - Command line argument parsing
- EventKit (system framework) - Calendar access

## Permissions

The app requires calendar access permissions. On first run, macOS will prompt you to grant calendar access. You can also manually grant this in System Preferences > Privacy & Security > Calendars.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
