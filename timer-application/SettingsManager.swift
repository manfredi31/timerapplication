//
//  SettingsManager.swift
//  timer-application
//

import Foundation
import Carbon
import Combine

struct TimerPreset: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var minutes: Int
    var seconds: Int
    
    var totalSeconds: Int {
        minutes * 60 + seconds
    }
    
    var displayName: String {
        if seconds == 0 {
            return "\(minutes)m"
        }
        return "\(minutes)m \(seconds)s"
    }
}

struct HotkeyConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    
    var displayString: String {
        var parts: [String] = []
        
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        
        if let keyString = keyCodeToString(keyCode) {
            parts.append(keyString)
        }
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        let keyMap: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            36: "Return", 48: "Tab", 51: "Delete", 53: "Escape",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        return keyMap[keyCode]
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var presets: [TimerPreset] {
        didSet { savePresets() }
    }
    
    @Published var selectedAlarmSound: String {
        didSet { UserDefaults.standard.set(selectedAlarmSound, forKey: "selectedAlarmSound") }
    }
    
    @Published var startTimerHotkey: HotkeyConfig? {
        didSet { saveHotkey(startTimerHotkey, forKey: "startTimerHotkey") }
    }
    
    @Published var pauseResumeHotkey: HotkeyConfig? {
        didSet { saveHotkey(pauseResumeHotkey, forKey: "pauseResumeHotkey") }
    }
    
    @Published var stopTimerHotkey: HotkeyConfig? {
        didSet { saveHotkey(stopTimerHotkey, forKey: "stopTimerHotkey") }
    }
    
    let availableSounds: [String] = ["Chime", "Bell", "Ping", "Alert", "Complete"]
    
    private init() {
        // Load presets
        if let data = UserDefaults.standard.data(forKey: "timerPresets"),
           let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data) {
            self.presets = decoded
        } else {
            self.presets = [
                TimerPreset(name: "Quick", minutes: 5, seconds: 0),
                TimerPreset(name: "Short", minutes: 10, seconds: 0),
                TimerPreset(name: "Pomodoro", minutes: 25, seconds: 0)
            ]
        }
        
        // Load sound
        self.selectedAlarmSound = UserDefaults.standard.string(forKey: "selectedAlarmSound") ?? "Chime"
        
        // Load hotkeys
        self.startTimerHotkey = loadHotkey(forKey: "startTimerHotkey")
        self.pauseResumeHotkey = loadHotkey(forKey: "pauseResumeHotkey")
        self.stopTimerHotkey = loadHotkey(forKey: "stopTimerHotkey")
    }
    
    private func savePresets() {
        if let encoded = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encoded, forKey: "timerPresets")
        }
    }
    
    private func saveHotkey(_ hotkey: HotkeyConfig?, forKey key: String) {
        if let hotkey = hotkey,
           let encoded = try? JSONEncoder().encode(hotkey) {
            UserDefaults.standard.set(encoded, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Notify hotkey manager to re-register
        NotificationCenter.default.post(name: .hotkeyConfigChanged, object: nil)
    }
    
    private func loadHotkey(forKey key: String) -> HotkeyConfig? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(HotkeyConfig.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    func updatePreset(at index: Int, name: String, minutes: Int, seconds: Int) {
        guard index < presets.count else { return }
        presets[index].name = name
        presets[index].minutes = minutes
        presets[index].seconds = seconds
    }
    
    func addPreset(name: String, minutes: Int, seconds: Int) {
        let preset = TimerPreset(name: name, minutes: minutes, seconds: seconds)
        presets.append(preset)
    }
    
    func removePreset(at index: Int) {
        guard index < presets.count else { return }
        presets.remove(at: index)
    }
}

extension Notification.Name {
    static let hotkeyConfigChanged = Notification.Name("hotkeyConfigChanged")
}

