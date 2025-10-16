# Calendar Menu App

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/Doka-NT/calendar-menu-app/ci.yml?branch=master) 
![GitHub issues](https://img.shields.io/github/issues/Doka-NT/calendar-menu-app)
![GitHub forks](https://img.shields.io/github/forks/Doka-NT/calendar-menu-app?style=social)
![GitHub stars](https://img.shields.io/github/stars/Doka-NT/calendar-menu-app?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/Doka-NT/calendar-menu-app?style=social)
![GitHub last commit](https://img.shields.io/github/last-commit/Doka-NT/calendar-menu-app)

Calendar Menu App is a macOS application that adds a calendar to your menu bar, displaying events scheduled for the current day. Events containing links to audio or video conferences open directly in the browser, while other events open in the calendar.

## Features

- **Menu Bar Integration**: Displays a list of today's events directly in the macOS menu bar.
- **Event Quick Actions**: Events with conference links open in the browser, and others open in the calendar app.
- **Notifications**: Timely reminders for upcoming events.
- **Customizable UI**: Events are styled with their respective calendar colors and icons.

## Technologies Used

- **Swift**: The application is built using Swift and the SwiftUI framework.
- **EventKit**: Utilized for accessing and managing calendar events.
- **AppKit**: Provides menu bar integration.
- **UserNotifications**: Manages local notifications for event reminders.
- **GitHub Actions**: Configured for CI/CD automation.

## Installation

1. Download the `.dmg` file from the [Releases](https://github.com/Doka-NT/calendar-menu-app/releases) section.
2. Double-click the `.dmg` file to open it.
3. Drag the app to your Applications folder.

## Usage

1. Launch the app from your Applications folder.
2. Grant access to your calendar and notifications when prompted.
3. Click the calendar icon in the menu bar to view today's events.

## Development

### Prerequisites

- macOS 12.0 or later
- Xcode 13 or later

### Building the Application

1. Clone the repository:
   ```bash
   git clone https://github.com/Doka-NT/calendar-menu-app.git
   ```
2. Open the project in Xcode:
   ```bash
   open CalendarMenuApp.xcodeproj
   ```
3. Build and run the project using the Xcode toolbar.

## CI/CD Workflow

The project is configured to use GitHub Actions for automated building and deployment:

- **Automatic Builds**: Triggered on every push to `main` or `master` and on pull request creation.
- **Releases**: Automatically created whenever a version tag (e.g., `v1.0.0`) is pushed.
- **Artifacts**: Downloadable `.dmg` files and `.app` bundles are available in the Actions section.

## License

This project is licensed under the [MIT License](LICENSE).
