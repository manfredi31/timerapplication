//
//  CalendarManager.swift
//  timer-application
//

import Foundation
import EventKit

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []
    
    // Store current event ID so we can delete it if timer is cancelled
    private var currentEventIdentifier: String?
    
    private init() {
        updateAuthorizationStatus()
    }
    
    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .fullAccess || authorizationStatus == .authorized {
            loadCalendars()
        }
    }
    
    func requestAccess() async -> Bool {
        do {
            // Use the modern API for macOS 14+
            if #available(macOS 14.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    self.updateAuthorizationStatus()
                }
                return granted
            } else {
                // Fallback for older macOS versions
                return await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, error in
                        DispatchQueue.main.async {
                            self.updateAuthorizationStatus()
                        }
                        continuation.resume(returning: granted)
                    }
                }
            }
        } catch {
            print("Calendar access request failed: \(error)")
            return false
        }
    }
    
    private func loadCalendars() {
        availableCalendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }
    }
    
    func calendar(withIdentifier identifier: String?) -> EKCalendar? {
        guard let identifier = identifier else {
            return eventStore.defaultCalendarForNewEvents
        }
        return eventStore.calendar(withIdentifier: identifier) ?? eventStore.defaultCalendarForNewEvents
    }
    
    func createTimerEvent(title: String, durationSeconds: Int, calendarIdentifier: String?) -> String? {
        guard authorizationStatus == .fullAccess || authorizationStatus == .authorized else {
            print("Calendar access not granted")
            return nil
        }
        
        guard let calendar = calendar(withIdentifier: calendarIdentifier) else {
            print("No calendar available")
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title.isEmpty ? "Timer" : title
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(TimeInterval(durationSeconds))
        event.calendar = calendar
        
        do {
            try eventStore.save(event, span: .thisEvent)
            currentEventIdentifier = event.eventIdentifier
            print("Created calendar event: \(event.title ?? "Timer")")
            return event.eventIdentifier
        } catch {
            print("Failed to save calendar event: \(error)")
            return nil
        }
    }
    
    func deleteCurrentEvent() {
        guard let identifier = currentEventIdentifier,
              let event = eventStore.event(withIdentifier: identifier) else {
            return
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            print("Deleted calendar event")
        } catch {
            print("Failed to delete calendar event: \(error)")
        }
        
        currentEventIdentifier = nil
    }
    
    func clearCurrentEventReference() {
        currentEventIdentifier = nil
    }
}
