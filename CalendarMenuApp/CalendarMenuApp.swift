//
//  CalendarMenuAppApp.swift
//  CalendarMenuApp
//
//  Created by Артем Сошников on 02.06.2024.
//

import SwiftUI
import AppKit
import EventKit

@main
struct CalendarMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
