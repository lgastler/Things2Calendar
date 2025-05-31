# Changesets Workflow for Things2Calendar

This project uses [Changesets](https://github.com/changesets/changesets) for version management and changelog generation.

## Adding Changes

When you make changes to the codebase:

1. **Add a changeset**:
   ```bash
   npm run changeset
   ```
   
2. **Follow the prompts**:
   - Select the type of change (major, minor, patch)
   - Write a description of the change
   - This creates a `.changeset/*.md` file

3. **Commit the changeset** with your changes:
   ```bash
   git add .changeset/
   git commit -m "feat: your feature description"
   ```

## Creating Releases

### Automated Release (Recommended)

1. **Merge changes** to main branch
2. **CI will automatically**:
   - Detect changesets
   - Update version and changelog
   - Create and push release tag
   - Build and publish release

### Manual Release

If you prefer manual control:

```bash
# Generate version and changelog
npx @changesets/cli version

# Review changes, then commit
git add -A && git commit -m "Release: version bump and changelog"

# Create and push tag
git tag v$(grep version Package.swift | head -1 | sed 's/.*"\(.*\)".*/\1/')
git push origin main --tags
```

## Changeset Types

- **Major** (breaking changes): `1.0.0` → `2.0.0`
- **Minor** (new features): `1.0.0` → `1.1.0` 
- **Patch** (bug fixes): `1.0.0` → `1.0.1`

## Examples

### Adding a Feature
```bash
npx @changesets/cli add
# Select: minor
# Description: "Add support for recurring time blocks"
```

### Fixing a Bug
```bash
npx @changesets/cli add
# Select: patch  
# Description: "Fix calendar permission handling on macOS Ventura"
```

### Breaking Change
```bash
npx @changesets/cli add
# Select: major
# Description: "Change CLI command structure for better UX"
```
