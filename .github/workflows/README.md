# GitHub Actions Workflows

This directory contains GitHub Actions workflows for building and releasing the CalendarMenuApp.

## Workflows

### 1. Build macOS App (`build.yml`)

This workflow builds the CalendarMenuApp on every push and pull request to the `main` or `master` branches.

**Triggers:**
- Push to `main` or `master` branches
- Pull requests to `main` or `master` branches
- Manual trigger via `workflow_dispatch`

**Steps:**
1. Checks out the repository
2. Sets up Xcode (latest stable version)
3. Builds the app using `xcodebuild`
4. Creates a DMG package
5. Uploads build artifacts (DMG and .app)

**Artifacts:**
- `CalendarMenuApp-dmg`: The DMG installer (retained for 30 days)
- `CalendarMenuApp-app`: The raw .app bundle (retained for 30 days)

### 2. Create Release (`release.yml`)

This workflow creates a GitHub release with the built DMG file.

**Triggers:**
- Push of tags matching `v*` (e.g., `v1.0.0`, `v1.1.0`)
- Manual trigger via `workflow_dispatch` with custom tag input

**Steps:**
1. Builds the app (same as build workflow)
2. Creates a DMG package
3. Creates a GitHub release with the DMG file attached

**Usage:**

To create a release:

1. **Using Git tags:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Using GitHub UI:**
   - Go to the "Actions" tab
   - Select "Create Release" workflow
   - Click "Run workflow"
   - Enter the desired tag name (e.g., `v1.0.0`)
   - Click "Run workflow"

## Build Configuration

The workflows use the following build settings:
- **Scheme:** CalendarMenuApp
- **Configuration:** Release
- **Code Signing:** Disabled (for CI builds)

The built app is not code-signed in the CI environment. For distribution, you'll need to sign the app manually or configure code signing in the workflow.

## Requirements

- macOS runner (automatically provided by GitHub Actions)
- Xcode (latest stable version is installed automatically)
- No additional secrets or configuration required for basic builds

## Notes

- Build artifacts are retained for 30 days
- The workflow disables code signing to allow builds without certificates
- DMG files are created using `hdiutil` with UDZO compression
