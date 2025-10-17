//
//  AppDelegate.swift
//  CalendarMenuApp
//
//  Created by Артем Сошников on 02.06.2024.
//

import Foundation
import AppKit
import EventKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let eventStore = EKEventStore()
    var notificationCenter: NotificationCenter {
        return .default
    }
    
    // MARK: - Conference domains storage
    // Default domains (kept from previous hardcoded values)
    private let defaultConferenceDomains: [String] = [
        "telemost.yandex.ru",
        "telemost.360.yandex.ru",
        "salutejazz.ru",
        "jazz.sber.ru"
    ]
    
    private let userDefaultsDomainsKey = "CustomConferenceDomains"
    
    private var customConferenceDomains: [String] {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: userDefaultsDomainsKey) ?? []
            return Array(Set(arr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })).sorted()
        }
        set {
            let normalized = Array(Set(newValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })).sorted()
            UserDefaults.standard.set(normalized, forKey: userDefaultsDomainsKey)
        }
    }
    
    private var allConferenceDomains: [String] {
        let defaults = defaultConferenceDomains.map { $0.lowercased() }
        let customs = customConferenceDomains
        return Array(Set(defaults + customs)).sorted()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Создаем элемент строки меню
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
            button.action = #selector(showMenu)
        }
        
        // Запрашиваем разрешение на доступ к календарю и отправку уведомлений
        requestCalendarAccess()
        requestNotificationAccess()

        // Начинаем наблюдение за изменениями в календаре
        startObservingCalendarChanges()
        
        setupNotificationActions()
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
                              let _ = extractURL(from: description) {
                        
                        // Добавляем иконку с телефоном к пункту меню
                        let phoneIcon = NSImage(named: NSImage.touchBarCommunicationVideoTemplateName)
                        let phoneMenuItem = NSMenuItem(title: eventTitle, action: #selector(handleMenuItemClick(_:)), keyEquivalent: "")
                        phoneMenuItem.representedObject = event
                        phoneMenuItem.image = phoneIcon
                        menuItem = phoneMenuItem
                    } else {
                        // Добавляем обычный пункт меню без иконки
                        menuItem = NSMenuItem(title: eventTitle, action: #selector(handleMenuItemClick(_:)), keyEquivalent: "")
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

        // Настройки доменов конференций (подменю)
        let domainsMenuItem = NSMenuItem(title: "Домены конференций", action: nil, keyEquivalent: "")
        let domainsSubmenu = NSMenu(title: "Домены конференций")
        
        // Секция: Дефолтные (только чтение)
        let defaultsHeader = NSMenuItem(title: "По умолчанию", action: nil, keyEquivalent: "")
        defaultsHeader.isEnabled = false
        domainsSubmenu.addItem(defaultsHeader)
        for d in defaultConferenceDomains.sorted() {
            let item = NSMenuItem(title: d, action: nil, keyEquivalent: "")
            item.isEnabled = false
            domainsSubmenu.addItem(item)
        }
        domainsSubmenu.addItem(NSMenuItem.separator())
        
        // Секция: Пользовательские (с удалением)
        let customHeader = NSMenuItem(title: "Пользовательские", action: nil, keyEquivalent: "")
        customHeader.isEnabled = false
        domainsSubmenu.addItem(customHeader)
        let customs = customConferenceDomains
        if customs.isEmpty {
            let empty = NSMenuItem(title: "(пусто)", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            domainsSubmenu.addItem(empty)
        } else {
            for d in customs {
                let removeItem = NSMenuItem(title: "Удалить: \(d)", action: #selector(removeCustomConferenceDomain(_:)), keyEquivalent: "")
                removeItem.target = self
                removeItem.representedObject = d
                domainsSubmenu.addItem(removeItem)
            }
        }
        
        domainsSubmenu.addItem(NSMenuItem.separator())
        
        // Действия: добавить/сбросить
        let addDomainItem = NSMenuItem(title: "Добавить домен…", action: #selector(addConferenceDomain), keyEquivalent: "")
        addDomainItem.target = self
        domainsSubmenu.addItem(addDomainItem)
        let resetDomainsItem = NSMenuItem(title: "Сбросить пользовательские", action: #selector(resetConferenceDomains), keyEquivalent: "")
        resetDomainsItem.target = self
        domainsSubmenu.addItem(resetDomainsItem)
        
        domainsMenuItem.submenu = domainsSubmenu
        menu.addItem(domainsMenuItem)
        menu.addItem(NSMenuItem.separator())

        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)
        
        // Показать меню
        statusItem.menu = menu
        statusItem.button?.performClick(nil) // Показать меню при нажатии на иконку
        statusItem.menu = nil // Сбросить меню после показа
    }

    // Удаление одного пользовательского домена
    @objc func removeCustomConferenceDomain(_ sender: NSMenuItem) {
        guard let domain = sender.representedObject as? String else { return }
        var updated = customConferenceDomains
        if let idx = updated.firstIndex(of: domain) {
            updated.remove(at: idx)
            customConferenceDomains = updated
        }
        self.showMenu()
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
    
    func openEvent(_ event: EKEvent) {
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
    
    @objc func handleMenuItemClick(_ sender: NSMenuItem) {
        if let event = sender.representedObject as? EKEvent {
            openEvent(event)
        }
    }

    func extractURL(from text: String) -> URL? {
        // Try link detection first
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = detector.matches(in: text, options: [], range: range)
            for match in matches {
                if let url = match.url, isConferenceURL(url) {
                    return url
                }
            }
        }
        // Fallback: substring search using known domains
        for domain in allConferenceDomains {
            let patterns = ["https://\(domain)", "http://\(domain)"]
            for pattern in patterns {
                if let range = text.range(of: pattern) {
                    let urlString = text[range.lowerBound...].components(separatedBy: .whitespacesAndNewlines).first ?? ""
                    if let url = URL(string: urlString), isConferenceURL(url) {
                        return url
                    }
                }
            }
        }
        return nil
    }

    private func isConferenceURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        for domain in allConferenceDomains {
            let d = domain.lowercased()
            if host == d || host.hasSuffix("." + d) {
                return true
            }
        }
        return false
    }

    private func normalizeDomainInput(_ input: String) -> String? {
        var trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        // If user pasted a full URL, extract host
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            if let url = URL(string: trimmed), let host = url.host?.lowercased() {
                return host
            }
        }
        // Remove leading www.
        if trimmed.hasPrefix("www.") {
            trimmed = String(trimmed.dropFirst(4))
        }
        // If contains path or spaces, attempt to parse as URL
        if trimmed.contains("/") {
            if let url = URL(string: "https://\(trimmed)"), let host = url.host?.lowercased() {
                return host
            }
        }
        // Very naive domain validation: must contain a dot
        guard trimmed.contains(".") else { return nil }
        return trimmed
    }

    // MARK: - Menu actions for managing domains
    @objc func addConferenceDomain() {
        let alert = NSAlert()
        alert.messageText = "Добавить домен конференции"
        alert.informativeText = "Например: zoom.us или meet.google.com. Можно вставить полную ссылку — домен извлечётся."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Добавить")
        alert.addButton(withTitle: "Отмена")
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        inputField.placeholderString = "пример: zoom.us"
        alert.accessoryView = inputField
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let text = inputField.stringValue
            if let domain = normalizeDomainInput(text) {
                var updated = customConferenceDomains
                if !updated.contains(domain) {
                    updated.append(domain)
                    customConferenceDomains = updated
                }
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Некорректный домен"
                errorAlert.informativeText = "Пожалуйста, укажите корректный домен, например: zoom.us"
                errorAlert.alertStyle = .warning
                errorAlert.addButton(withTitle: "OK")
                errorAlert.runModal()
            }
            // Обновим меню после добавления
            self.showMenu()
        }
    }

    @objc func resetConferenceDomains() {
        // Сбрасываем только пользовательские домены
        customConferenceDomains = []
        let alert = NSAlert()
        alert.messageText = "Доменные настройки сброшены"
        alert.informativeText = "Используются значения по умолчанию."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        self.showMenu()
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

    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { [weak self] (granted, error) in
            guard let self = self else { return }
            if granted {
                self.scheduleNotificationsForUpcomingEvents()
            } else if let error = error {
                print("Error requesting calendar access: \(error.localizedDescription)")
            }
        }
    }

    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permission granted")
            } else if let error = error {
                print("Error requesting authorization: \(error.localizedDescription)")
            }
        }
    }

    func startObservingCalendarChanges() {
        notificationCenter.addObserver(self,
                                       selector: #selector(calendarChanged),
                                       name: .EKEventStoreChanged,
                                       object: eventStore)
    }

    @objc func calendarChanged(notification: NSNotification) {
        // При изменении в календаре, пересчитываем расписание уведомлений
        scheduleNotificationsForUpcomingEvents()
    }

    func scheduleNotificationsForUpcomingEvents() {
        let calendars = eventStore.calendars(for: .event)
        let oneDayAgo = Date(timeIntervalSinceNow: -24*60*60)
        let oneDayAfter = Date(timeIntervalSinceNow: 24*60*60)

        let predicate = eventStore.predicateForEvents(withStart: oneDayAgo, end: oneDayAfter, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        // Удаляем все ранее добавленные уведомления перед добавлением новых
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for event in events {
            scheduleNotification(for: event)
        }
    }

    func scheduleNotification(for event: EKEvent) {
        let content = UNMutableNotificationContent()
        let title = event.title ?? ""
        content.title = event.title
        content.body = "Событие \(title) начинается."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "EVENT_REMINDER_CATEGORY"
        content.userInfo = ["eventIdentifier": event.eventIdentifier]

        guard let eventDate = event.startDate else { return }
        let timeInterval = eventDate.timeIntervalSinceNow - 60

        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }

    
    func setupNotificationActions() {
        let viewEventAction = UNNotificationAction(identifier: "VIEW_EVENT",
                                                   title: "View Event",
                                                   options: .foreground)
        let category = UNNotificationCategory(identifier: "EVENT_REMINDER_CATEGORY",
                                              actions: [viewEventAction],
                                              intentIdentifiers: [],
                                              options: [])

        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier != "VIEW_EVENT" {
            let userInfo = response.notification.request.content.userInfo
            if let eventID = userInfo["eventIdentifier"] as? String, let event = eventStore.event(withIdentifier: eventID) {
                handleEvent(event)
            }
        }
        completionHandler()
    }

    func handleEvent(_ event: EKEvent) {
        openEvent(event)
    }
}
