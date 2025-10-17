# Calendar Menu App - AI Coding Instructions

## Project Overview
macOS menu bar application that displays today's calendar events with smart link detection for video conferences. Built with SwiftUI and EventKit.

## Architecture

### Core Components
- **CalendarMenuApp.swift**: SwiftUI app entry point with `NSApplicationDelegateAdaptor`
- **AppDelegate.swift**: Main application logic - owns menu bar lifecycle, event loading, and notification scheduling
- **ContentView.swift**: Placeholder SwiftUI view (not used in menu bar flow)

### Key Pattern: Menu Bar-Only Application
This app has **no visible window**. All UI is through `NSStatusItem` in the menu bar. The SwiftUI `Scene` returns `EmptyView()` intentionally.

## Critical Workflows

### Building & Running
```bash
# Build from command line
xcodebuild -scheme "CalendarMenuApp" -project CalendarMenuApp.xcodeproj -configuration Release clean build CODE_SIGN_IDENTITY="-"

# Or use Xcode with CalendarMenuApp.xcscheme or "CalendarMenuApp Release.xcscheme"
```

### Creating Releases
1. Push a version tag: `git tag v1.0.0 && git push origin v1.0.0`
2. GitHub Actions automatically builds and creates release with DMG
3. Manual release script: `./release.sh path/to/CalendarMenuApp.app`

## Code Conventions

### Event Processing (AppDelegate.swift)
- **Conference detection**: Hardcoded URL patterns for Yandex Telemost, SalutJazz, Jazz.Sber
  - Pattern: Check `event.notes` for specific URLs using `extractURL(from:)`
  - Conference events get phone icon (`touchBarCommunicationVideoTemplateName`)
  - Non-conference events open in Calendar app via `ical://` scheme
  
- **Event filtering**: Only shows non-all-day events (`!event.isAllDay`)
- **Time window**: Loads events from `startOfDay` to `endOfDay` using `EKEventStore.predicateForEvents`

### Notification Scheduling Pattern
1. Observer pattern: `NotificationCenter` watches `.EKEventStoreChanged`
2. On calendar change: Clear all pending notifications, reschedule for upcoming events
3. Timing: Notifications fire 60 seconds before event (`timeInterval: eventDate.timeIntervalSinceNow - 60`)

### Permissions & Entitlements
**Critical**: Both `Info.plist` and `CalendarMenuApp.entitlements` must be kept in sync
- Calendar access: `NSCalendarsUsageDescription` in Info.plist + `com.apple.security.personal-information.calendars` in entitlements
- Sandbox: App runs sandboxed (`com.apple.security.app-sandbox`)

## Integration Points

### macOS Frameworks
- **EventKit**: `EKEventStore` is shared instance in AppDelegate, reused across calendar operations
- **UserNotifications**: `UNUserNotificationCenter` with custom category `EVENT_REMINDER_CATEGORY`
- **NSWorkspace**: Opens URLs in browser or Calendar app based on event type

### CI/CD Pipeline
- **build.yml**: Triggers on push to main/master and PRs
- **release.yml**: Triggers on version tags (`v*`) or manual workflow dispatch
- Both use `CODE_SIGN_IDENTITY="-"` for ad-hoc signing (no Apple Developer certificate needed for builds)

## Project-Specific Quirks

1. **Russian localization**: UI strings in Russian (e.g., `"Событие \(title) начинается"`)
2. **Calendar colors**: Menu items include colored circles from `event.calendar.color`
3. **Past events**: Grayed out using `NSAttributedString` with `.lightGray` color
4. **URL extraction**: Must handle Yandex 360 and Sber Jazz URLs specifically - generic URL parsing won't work

## Common Tasks

### Adding New Conference Platform
Edit `AppDelegate.swift`:
1. Add URL pattern to `extractURL(from:)` patterns array
2. Add URL check to conference detection if-statement in `showMenu()`

### Modifying Notification Timing
Change offset in `scheduleNotification(for:)`: `eventDate.timeIntervalSinceNow - 60` (currently 1 minute before)

### Debugging Calendar Access
Check both permission requests: `requestCalendarAccess()` and ensure entitlements match Info.plist

## Files to Ignore
- `ContentView.swift`: Not used in app flow (menu bar apps don't need SwiftUI views)
- `Preview Content/`: SwiftUI previews aren't functional for NSApplicationDelegate-based apps
