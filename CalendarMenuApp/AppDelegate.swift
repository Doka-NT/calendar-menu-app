//
//  AppDelegate.swift
//  CalendarMenuApp
//
//  Created by Артем Сошников on 02.06.2024.
//

import Foundation
import AppKit
import EventKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Создаем элемент строки меню
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
            button.action = #selector(showMenu)
        }
        
        let eventStore = EKEventStore()

        eventStore.requestAccess(to: .event) { (granted, error) in
            if granted {
                // Доступ предоставлен
            } else {
                // Доступ не предоставлен
                print("Access to calendar was not granted: \(String(describing: error?.localizedDescription))")
            }
        }

    }
    
    @objc func showMenu() {
        let menu = NSMenu()
        
        // Загружаем события из календаря
        let events = loadEventsForToday()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm" // Формат времени
        
        for event in events {
            // Проверяем, занимает ли событие весь день
            if !event.isAllDay {
                // Получаем время начала события
                if let startTime = event.startDate {
                    let startTimeString = dateFormatter.string(from: startTime)
                    
                    // Формируем строку вида "Время начала - Название события"
                    var eventTitle = "\(startTimeString)"
                    if let title = event.title {
                        eventTitle += " - \(title)"
                    }
                    
                    // Извлекаем URL из описания события
                    let menuItem: NSMenuItem
                    if let description = event.notes,
                       let url = extractURL(from: description),
                       let urlString = url.absoluteString.lowercased() as NSString?,
                       urlString.range(of: "telemost.yandex.ru").location != NSNotFound ||
                       urlString.range(of: "salutejazz.ru").location != NSNotFound ||
                       urlString.range(of: "jazz.sber.ru").location != NSNotFound {
                        
                        // Добавляем иконку с телефоном к пункту меню
                        let phoneIcon = NSImage(named: NSImage.touchBarCommunicationVideoTemplateName)
                        let phoneMenuItem = NSMenuItem(title: eventTitle, action: #selector(openEvent(_:)), keyEquivalent: "")
                        phoneMenuItem.representedObject = event
                        phoneMenuItem.image = phoneIcon
                        menuItem = phoneMenuItem
                    } else {
                        // Добавляем обычный пункт меню без иконки
                        menuItem = NSMenuItem(title: eventTitle, action: #selector(openEvent(_:)), keyEquivalent: "")
                        menuItem.representedObject = event
                        menuItem.indentationLevel = 2
                    }
                    
                    if event.endDate < Date() {
                        menuItem.attributedTitle = NSAttributedString(string: eventTitle, attributes: [.foregroundColor: NSColor.lightGray])
                    }
                    
                    // Добавление кружочка с цветом календаря
                    let colorCircle = createColorCircle(for: event.calendar)
                    menu.addItem(menuItem)
                }
            }
        }
        
        menu.addItem(NSMenuItem.separator()) // Разделитель между событиями и кнопкой Quit

        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)
        
        // Показать меню
        statusItem.menu = menu
        statusItem.button?.performClick(nil) // Показать меню при нажатии на иконку
        statusItem.menu = nil // Сбросить меню после показа
    }
    
    func loadEventsForToday() -> [EKEvent] {
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        return events
    }
    
    @objc func openEvent(_ sender: NSMenuItem) {
        if let event = sender.representedObject as? EKEvent {
            let description = event.notes ?? ""
            if let url = extractURL(from: description) {
                NSWorkspace.shared.open(url)
            } else {
                // Открыть событие в календаре
                if let eventURL = URL(string: "ical://ekevent/\(event.eventIdentifier)") {
                    NSWorkspace.shared.open(eventURL)
                }
            }
        }
    }

    func extractURL(from text: String) -> URL? {
        let patterns = ["https://telemost.yandex.ru", "https://salutejazz.ru", "https://jazz.sber.ru"]
        for pattern in patterns {
            if let range = text.range(of: pattern) {
                let urlString = text[range.lowerBound...].components(separatedBy: .whitespacesAndNewlines).first ?? ""
                return URL(string: urlString)
            }
        }
        return nil
    }
    
    func createColorCircle(for calendar: EKCalendar) -> NSImage {
        let size = NSSize(width: 10, height: 10)
        let image = NSImage(size: size)
        image.lockFocus()
        calendar.color.setFill()
        let circle = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size))
        circle.fill()
        image.unlockFocus()
        return image
    }

}
