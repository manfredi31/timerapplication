//
//  MenuBarView.swift
//  timer-application

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var timerManager = TimerManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var sliderValue: Double = 0
    @State private var taskDescription: String = ""
    @State private var isDragging = false
    @State private var isHoveringFloatButton = false
    
    private let maxSliderMinutes: Double = 60
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Slider and action icons
            topBarSection
            
            // Preset buttons row
            presetButtonsSection
            
            // Bottom row: Task input, start button, and timer display
            bottomSection
        }
        .padding(16)
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Top Bar with Slider and Icons
    private var topBarSection: some View {
        HStack(spacing: 12) {
            // Time slider
            GeometryReader { geometry in
                let currentValue = isDragging ? sliderValue : effectiveSliderValue
                let normalizedValue = min(1.0, currentValue / maxSliderMinutes)
                
                ZStack(alignment: .leading) {
                    // Track background
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Filled portion
                    Rectangle()
                        .fill(Color.primary.opacity(0.6))
                        .frame(width: max(0, geometry.size.width * normalizedValue), height: 4)
                        .cornerRadius(2)
                    
                    // Slider handle
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 12, height: 12)
                        .offset(x: max(0, min(geometry.size.width - 12, (geometry.size.width - 12) * normalizedValue)))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let newValue = (value.location.x / geometry.size.width) * maxSliderMinutes
                                    sliderValue = max(0, min(maxSliderMinutes, newValue))
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    // If timer is running, this allows scrubbing to change the timer
                                }
                        )
                }
            }
            .frame(height: 12)
            
            // Action icons
            HStack(spacing: 8) {
                // Settings button
                Button(action: {
                    NotificationCenter.default.post(name: .showSettings, object: nil)
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
                
                // Floating display toggle
                Button(action: {
                    NotificationCenter.default.post(name: .showFloatingWindow, object: nil)
                }) {
                    Image(systemName: "pip")
                        .font(.system(size: 13))
                        .foregroundColor(isHoveringFloatButton ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringFloatButton = hovering
                }
                .help("Toggle floating display")
            }
        }
    }
    
    // MARK: - Preset Buttons
    private var presetButtonsSection: some View {
        HStack(spacing: 12) {
            ForEach(settingsManager.presets.prefix(3)) { preset in
                Button(action: {
                    selectPreset(preset)
                }) {
                    Text(preset.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // More options button
            Menu {
                ForEach(settingsManager.presets.dropFirst(3)) { preset in
                    Button(preset.displayName) {
                        selectPreset(preset)
                    }
                }
                
                Divider()
                
                Button("Settings...") {
                    NotificationCenter.default.post(name: .showSettings, object: nil)
                }
            } label: {
                Text("...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 20)
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // Left side: Task input and start button
            VStack(alignment: .leading, spacing: 8) {
                // Task description input
                TextField("", text: $taskDescription)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .frame(width: 100)
                    .overlay(
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                            .offset(y: 10),
                        alignment: .bottom
                    )
                
                // Start button
                Button(action: startTimer) {
                    Text("start")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Right side: Timer display
            timerDisplay
        }
    }
    
    // MARK: - Timer Display
    private var timerDisplay: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(displayTime)
                .font(.system(size: 42, weight: .light, design: .default))
                .foregroundColor(.primary)
                .monospacedDigit()
            
            // Timer controls (only show when timer is active)
            if timerManager.state != .idle {
                HStack(spacing: 12) {
                    Button(action: {
                        timerManager.togglePauseResume()
                    }) {
                        Image(systemName: timerManager.state == .running ? "pause" : "play")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        timerManager.stopTimer()
                        sliderValue = 0
                    }) {
                        Image(systemName: "stop")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var displayTime: String {
        if timerManager.state != .idle {
            return timerManager.formattedTime
        }
        
        // Show slider time
        let totalMinutes = Int(sliderValue)
        let totalSeconds = Int((sliderValue - Double(totalMinutes)) * 60)
        return String(format: "%02d:%02d", totalMinutes, totalSeconds)
    }
    
    private var effectiveSliderValue: Double {
        if timerManager.state != .idle && !isDragging {
            return Double(timerManager.timeRemaining) / 60.0
        }
        return sliderValue
    }
    
    // MARK: - Actions
    private func startTimer() {
        let totalMinutes = Int(sliderValue)
        let totalSeconds = Int((sliderValue - Double(totalMinutes)) * 60)
        
        guard totalMinutes > 0 || totalSeconds > 0 else { return }
        
        timerManager.startTimer(minutes: totalMinutes, seconds: totalSeconds, task: taskDescription)
    }
    
    private func selectPreset(_ preset: TimerPreset) {
        sliderValue = Double(preset.minutes) + Double(preset.seconds) / 60.0
    }
}

extension Notification.Name {
    static let showFloatingWindow = Notification.Name("showFloatingWindow")
    static let showSettings = Notification.Name("showSettings")
}

#Preview {
    MenuBarView()
}
