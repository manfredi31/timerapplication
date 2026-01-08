//
//  timer_applicationApp.swift
//  timer-application
//

import SwiftUI
import AppKit
import UserNotifications

@main
struct timer_applicationApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var timerManager = TimerManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar only app
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar
        setupMenuBar()
        
        // Setup hotkey handlers
        setupHotkeyHandlers()
        
        // Observe timer changes to update menu bar
        setupTimerObserver()
        
        // Setup notification observers
        setupNotificationObservers()
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "⏱"
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
    }
    
    private func setupTimerObserver() {
        // Observe time remaining changes
        timerManager.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)
        
        // Observe state changes
        timerManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)
        
        // Observe task description changes
        timerManager.$taskDescription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)
    }
    
    private func updateMenuBarDisplay() {
        statusItem.button?.title = timerManager.menuBarDisplay
    }
    
    
    private func setupHotkeyHandlers() {
        let hotkeyManager = HotkeyManager.shared
        
        hotkeyManager.onStartHotkey = { [weak self] in
            self?.showPopoverForNewTimer()
        }
        
        hotkeyManager.onPauseResumeHotkey = {
            TimerManager.shared.togglePauseResume()
        }
        
        hotkeyManager.onStopHotkey = {
            TimerManager.shared.stopTimer()
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showFloatingWindow),
            name: .showFloatingWindow,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSettings),
            name: .showSettings,
            object: nil
        )
    }
    
    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    private func showPopoverForNewTimer() {
        if let button = statusItem.button {
            if !popover.isShown {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc private func showFloatingWindow() {
        popover.performClose(nil)
        FloatingTimerWindowController.shared.show()
    }
    
    @objc private func showSettings() {
        popover.performClose(nil)
        SettingsWindowController.shared.show()
    }
}

// Import Combine for AnyCancellable
import Combine
