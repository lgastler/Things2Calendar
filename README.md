# Things2Calendar

[![Release](https://img.shields.io/github/v/release/lgastler/Things2Calendar)](https://github.com/lgastler/Things2Calendar/releases)

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
brew install lgastler/tap/things2calendar
```

### Manual Installation

1. Download the latest release from [GitHub Releases](https://github.com/lgastler/Things2Calendar/releases)
2. Install the binary:

```bash
# Download and install
curl -L https://github.com/lgastler/Things2Calendar/releases/latest/download/Things2Calendar-*-macos.tar.gz | tar xz
sudo mv Things2Calendar /usr/local/bin/
sudo mv t2c /usr/local/bin/
```

### Apple Shortcuts Setup

To enable automatic syncing, you'll need to install the Things2Calendar shortcut:

1. [Install the Things2Calendar Shortcut](https://www.icloud.com/shortcuts/d8433f7eda784d3ca6013a32e5a007ea)
2. Open the Shortcuts app
3. Configure the shortcut to run on your preferred schedule
4. Grant necessary permissions when prompted

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
- Apple Shortcuts app (for automated syncing)

## Development

### Local Development

```bash
git clone https://github.com/lgastler/Things2Calendar.git
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

### Release Management

This project uses [Changesets](https://github.com/changesets/changesets) for version management and changelog generation.

#### Making Changes

When contributing changes:

```bash
# Add a changeset describing your change
npx @changesets/cli add

# Commit your changes WITH the changeset
git add -A && git commit -m "feat: your feature description"
git push origin feature-branch
```

#### Release Process

**Automated (Recommended):**

1. Merge your PR to `main`
2. Changesets automatically creates a "Version Packages" PR
3. Review and merge the Version Packages PR
4. Release is automatically built and published! 🚀

**Manual Release:**

```bash
# Generate version bump and changelog
npx @changesets/cli version

# Review changes, then commit and push
git add -A && git commit -m "chore: release packages"
git push origin main

# Create tag to trigger release build
git tag v$(grep "^## " CHANGELOG.md | head -1 | sed 's/## //')
git push origin --tags
```

#### Changeset Types

- `major`: Breaking changes (1.0.0 → 2.0.0)
- `minor`: New features (1.0.0 → 1.1.0)
- `patch`: Bug fixes (1.0.0 → 1.0.1)

For detailed workflow documentation, see [`docs/CHANGESETS.md`](docs/CHANGESETS.md).

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
