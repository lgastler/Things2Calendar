# Calverge CLI

[![Release](https://img.shields.io/github/v/release/lgastler/calverge-cli)](https://github.com/lgastler/calverge-cli/releases)

A command-line utility to sync events between macOS calendars with support for different sync modes.

## Features

- **Full Sync**: Copy complete event details (title, location, notes, alarms, recurrence)
- **Busy-Only Sync**: Create generic "Busy" time blocks for privacy
- **Safe Operation**: Only modifies target calendar, preserves past events
- **Flexible Input**: Use JSON config files or command-line arguments
- **Smart Cleanup**: Removes previously synced events before re-syncing

## Installation

### Homebrew (Recommended)

```bash
brew install lgastler/tap/calverge
```

### Direct Download

Download the latest release from [GitHub Releases](https://github.com/lgastler/calverge-cli/releases):

```bash
# Download and install the latest version
curl -L https://github.com/lgastler/calverge-cli/releases/latest/download/calverge-*-macos.tar.gz | tar xz
sudo mv calverge /usr/local/bin/
```

Or download a specific version:

```bash
# Replace VERSION with the desired version (e.g., 1.0.0)
curl -L https://github.com/lgastler/calverge-cli/releases/download/vVERSION/calverge-VERSION-macos.tar.gz | tar xz
sudo mv calverge /usr/local/bin/
```

### Manual Installation

1. Clone the repository:

```bash
git clone https://github.com/lgastler/calverge-cli.git
cd calverge-cli
```

2. Build the project:

```bash
swift build -c release
```

3. Install the binary:

```bash
sudo cp .build/release/calverge /usr/local/bin/
```

## Usage

### List Available Calendars

First, discover your calendar IDs:

```bash
calverge calendars
```

This will show all calendars with their IDs, permissions, and sources.

### Sync Using Command-Line Arguments

**Full sync with basic details:**

```bash
calverge sync --target "CAL-TARGET-123" --sources "CAL-SOURCE-1,CAL-SOURCE-2"
```

**Full sync with all details (notes, alarms, recurrence):**

```bash
calverge sync --target "CAL-TARGET-123" --sources "CAL-SOURCE-1" --include-details
```

**Privacy mode (busy-only):**

```bash
calverge sync --target "CAL-TARGET-123" --sources "CAL-SOURCE-1" --mode busy-only
```

### Sync Using JSON Configuration

Create a JSON config file (see examples below) and run:

```bash
calverge sync --config work-sync.json
```

## Configuration Examples

### Full Sync Configuration

```json
{
  "name": "Work Calendar Sync",
  "targetCalendarID": "CAL-TARGET-123",
  "sourceCalendarIDs": ["CAL-WORK-456", "CAL-MEETINGS-789"],
  "syncMode": "full",
  "includeDetails": true
}
```

### Privacy Sync Configuration

```json
{
  "name": "Privacy Sync",
  "targetCalendarID": "CAL-SHARED-123",
  "sourceCalendarIDs": ["CAL-PERSONAL-456"],
  "syncMode": "busy-only",
  "includeDetails": false
}
```

## Sync Modes

- **`full`**: Copy all event details including title, location, and optionally notes/alarms/recurrence
- **`busy-only`**: Create generic "Busy" events showing only time blocks (for privacy)

## How It Works

1. **Cleanup**: Removes previously synced events from the target calendar (future events only)
2. **Copy**: Creates new events in the target calendar based on source calendars
3. **Metadata**: Adds tracking information to synced events for future cleanup
4. **Safety**: Only modifies the target calendar, never touches source calendars

## Command Reference

```bash
# List all calendars with IDs
calverge calendars

# Sync with command-line arguments
calverge sync --target <id> --sources <id1,id2> [--mode full|busy-only] [--include-details]

# Sync with JSON config
calverge sync --config <path-to-json>

# Get help
calverge --help
calverge sync --help
```

## Requirements

- macOS 14.0 or later
- Calendar access permissions (granted on first run)

## Development

### Local Development

```bash
git clone https://github.com/lgastler/calverge-cli.git
cd calverge-cli

# Build debug version
swift build

# Build release version
swift build -c release

# Run tests
swift test

# Quick test
.build/debug/calverge calendars

# Install globally
sudo cp .build/release/calverge /usr/local/bin/
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
