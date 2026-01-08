//
//  HotkeyManager.swift
//  timer-application
//

import Foundation
import Carbon
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var startHotkeyRef: EventHotKeyRef?
    private var pauseResumeHotkeyRef: EventHotKeyRef?
    private var stopHotkeyRef: EventHotKeyRef?
    
    private var eventHandler: EventHandlerRef?
    
    private let startHotkeyID = EventHotKeyID(signature: OSType(0x54494D31), id: 1) // TIM1
    private let pauseResumeHotkeyID = EventHotKeyID(signature: OSType(0x54494D32), id: 2) // TIM2
    private let stopHotkeyID = EventHotKeyID(signature: OSType(0x54494D33), id: 3) // TIM3
    
    var onStartHotkey: (() -> Void)?
    var onPauseResumeHotkey: (() -> Void)?
    var onStopHotkey: (() -> Void)?
    
    private init() {
        setupEventHandler()
        registerHotkeys()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeyConfigChanged),
            name: .hotkeyConfigChanged,
            object: nil
        )
    }
    
    @objc private func hotkeyConfigChanged() {
        unregisterAllHotkeys()
        registerHotkeys()
    }
    
    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { (_, event, _) -> OSStatus in
            var hotkeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
            
            DispatchQueue.main.async {
                switch hotkeyID.id {
                case 1:
                    HotkeyManager.shared.onStartHotkey?()
                case 2:
                    HotkeyManager.shared.onPauseResumeHotkey?()
                case 3:
                    HotkeyManager.shared.onStopHotkey?()
                default:
                    break
                }
            }
            
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandler)
    }
    
    func registerHotkeys() {
        let settings = SettingsManager.shared
        
        if let config = settings.startTimerHotkey {
            var hotkeyID = startHotkeyID
            _ = RegisterEventHotKey(config.keyCode, config.modifiers, hotkeyID, GetApplicationEventTarget(), 0, &startHotkeyRef)
        }
        
        if let config = settings.pauseResumeHotkey {
            var hotkeyID = pauseResumeHotkeyID
            _ = RegisterEventHotKey(config.keyCode, config.modifiers, hotkeyID, GetApplicationEventTarget(), 0, &pauseResumeHotkeyRef)
        }
        
        if let config = settings.stopTimerHotkey {
            var hotkeyID = stopHotkeyID
            _ = RegisterEventHotKey(config.keyCode, config.modifiers, hotkeyID, GetApplicationEventTarget(), 0, &stopHotkeyRef)
        }
    }
    
    private func unregisterAllHotkeys() {
        if let ref = startHotkeyRef {
            UnregisterEventHotKey(ref)
            startHotkeyRef = nil
        }
        if let ref = pauseResumeHotkeyRef {
            UnregisterEventHotKey(ref)
            pauseResumeHotkeyRef = nil
        }
        if let ref = stopHotkeyRef {
            UnregisterEventHotKey(ref)
            stopHotkeyRef = nil
        }
    }
    
    deinit {
        unregisterAllHotkeys()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
}

// Helper for recording hotkeys in settings
class HotkeyRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordedHotkey: HotkeyConfig?
    
    private var monitor: Any?
    
    func startRecording() {
        isRecording = true
        recordedHotkey = nil
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isRecording else { return event }
            
            let modifiers = event.modifierFlags
            var carbonModifiers: UInt32 = 0
            
            if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
            if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
            if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
            if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
            
            // Require at least one modifier
            if carbonModifiers != 0 {
                self.recordedHotkey = HotkeyConfig(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
                self.stopRecording()
            }
            
            return nil
        }
    }
    
    func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

