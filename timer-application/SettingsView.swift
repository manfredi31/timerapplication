//
//  SettingsView.swift
//  timer-application
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PresetsSettingsView()
                .tabItem {
                    Label("Presets", systemImage: "timer")
                }
                .tag(0)
            
            SoundsSettingsView()
                .tabItem {
                    Label("Sounds", systemImage: "speaker.wave.2")
                }
                .tag(1)
            
            HotkeysSettingsView()
                .tabItem {
                    Label("Hotkeys", systemImage: "command")
                }
                .tag(2)
        }
        .frame(width: 450, height: 350)
    }
}

struct PresetsSettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var editingPreset: TimerPreset?
    @State private var showingAddPreset = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timer Presets")
                .font(.headline)
            
            Text("Configure quick-start timer presets that appear in the menu bar.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            List {
                ForEach(Array(settingsManager.presets.enumerated()), id: \.element.id) { index, preset in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(preset.name)
                                .font(.system(size: 13, weight: .medium))
                            Text(preset.displayName)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            editingPreset = preset
                        }
                        .buttonStyle(.borderless)
                        
                        Button(role: .destructive) {
                            settingsManager.removePreset(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                        .disabled(settingsManager.presets.count <= 1)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.bordered)
            .frame(height: 150)
            
            HStack {
                Spacer()
                Button("Add Preset") {
                    showingAddPreset = true
                }
            }
        }
        .padding(20)
        .sheet(item: $editingPreset) { preset in
            PresetEditorView(preset: preset) { updated in
                if let index = settingsManager.presets.firstIndex(where: { $0.id == preset.id }) {
                    settingsManager.updatePreset(at: index, name: updated.name, minutes: updated.minutes, seconds: updated.seconds)
                }
            }
        }
        .sheet(isPresented: $showingAddPreset) {
            PresetEditorView(preset: nil) { newPreset in
                settingsManager.addPreset(name: newPreset.name, minutes: newPreset.minutes, seconds: newPreset.seconds)
            }
        }
    }
}

struct PresetEditorView: View {
    let preset: TimerPreset?
    let onSave: (TimerPreset) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var minutes: String = ""
    @State private var seconds: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(preset == nil ? "Add Preset" : "Edit Preset")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Preset name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Minutes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $minutes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seconds")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $seconds)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    let newPreset = TimerPreset(
                        id: preset?.id ?? UUID(),
                        name: name,
                        minutes: Int(minutes) ?? 0,
                        seconds: Int(seconds) ?? 0
                    )
                    onSave(newPreset)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || ((Int(minutes) ?? 0) == 0 && (Int(seconds) ?? 0) == 0))
            }
        }
        .padding(20)
        .frame(width: 300, height: 220)
        .onAppear {
            if let preset = preset {
                name = preset.name
                minutes = String(preset.minutes)
                seconds = String(preset.seconds)
            }
        }
    }
}

struct SoundsSettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alarm Sound")
                .font(.headline)
            
            Text("Choose the sound that plays when your timer completes.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Sound", selection: $settingsManager.selectedAlarmSound) {
                ForEach(settingsManager.availableSounds, id: \.self) { sound in
                    Text(sound).tag(sound)
                }
            }
            .pickerStyle(.radioGroup)
            .padding(.leading, 4)
            
            HStack {
                Button("Preview Sound") {
                    playPreviewSound()
                }
            }
            
            Spacer()
            
            Text("Note: The app uses system sounds. Custom sounds can be added to the app bundle.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
    }
    
    private func playPreviewSound() {
        NSSound.beep()
    }
}

struct HotkeysSettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @StateObject private var startRecorder = HotkeyRecorder()
    @StateObject private var pauseRecorder = HotkeyRecorder()
    @StateObject private var stopRecorder = HotkeyRecorder()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.headline)
            
            Text("Set global hotkeys to control the timer from anywhere.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                HotkeyRow(
                    label: "Start New Timer",
                    currentHotkey: settingsManager.startTimerHotkey,
                    recorder: startRecorder,
                    onSet: { settingsManager.startTimerHotkey = $0 },
                    onClear: { settingsManager.startTimerHotkey = nil }
                )
                
                HotkeyRow(
                    label: "Pause/Resume Timer",
                    currentHotkey: settingsManager.pauseResumeHotkey,
                    recorder: pauseRecorder,
                    onSet: { settingsManager.pauseResumeHotkey = $0 },
                    onClear: { settingsManager.pauseResumeHotkey = nil }
                )
                
                HotkeyRow(
                    label: "Stop Timer",
                    currentHotkey: settingsManager.stopTimerHotkey,
                    recorder: stopRecorder,
                    onSet: { settingsManager.stopTimerHotkey = $0 },
                    onClear: { settingsManager.stopTimerHotkey = nil }
                )
            }
            
            Spacer()
            
            Text("Click 'Record' then press your desired key combination (must include ⌘, ⌃, ⌥, or ⇧)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
    }
}

struct HotkeyRow: View {
    let label: String
    let currentHotkey: HotkeyConfig?
    @ObservedObject var recorder: HotkeyRecorder
    let onSet: (HotkeyConfig) -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 150, alignment: .leading)
            
            Spacer()
            
            if recorder.isRecording {
                Text("Press keys...")
                    .foregroundColor(.secondary)
                    .frame(width: 100)
                
                Button("Cancel") {
                    recorder.stopRecording()
                }
            } else {
                Text(currentHotkey?.displayString ?? "Not set")
                    .foregroundColor(currentHotkey == nil ? .secondary : .primary)
                    .frame(width: 100)
                
                Button("Record") {
                    recorder.startRecording()
                }
                
                if currentHotkey != nil {
                    Button("Clear") {
                        onClear()
                    }
                }
            }
        }
        .onChange(of: recorder.recordedHotkey) { _, newValue in
            if let hotkey = newValue {
                onSet(hotkey)
            }
        }
    }
}

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Timer Settings"
        window.center()
        
        super.init(window: window)
        
        let hostingView = NSHostingView(rootView: SettingsView())
        window.contentView = hostingView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

#Preview {
    SettingsView()
}

