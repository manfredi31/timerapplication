//
//  MenuBarView.swift
//  timer-application

import SwiftUI

enum MenuBarField: Hashable {
    case minutes
    case task
}

struct MenuBarView: View {
    @ObservedObject var timerManager = TimerManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var sliderValue: Double = 0
    @State private var isDragging = false
    @State private var taskDescription: String = ""
    @State private var minutesInput: String = ""
    @FocusState private var focusedField: MenuBarField?
    
    private let maxSliderMinutes: Double = 120
    
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
        .frame(width: 350)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Set initial focus to minutes field when popover opens (only if idle)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if timerManager.state == .idle {
                    focusedField = .minutes
                }
            }
        }
    }
    
    // MARK: - Top Bar with Slider and Icons
    private var topBarSection: some View {
        // Time slider with ruler-like appearance
        GeometryReader { geometry in
            let currentValue = isDragging ? sliderValue : effectiveSliderValue
            let normalizedValue = min(1.0, currentValue / maxSliderMinutes)
            
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 32)
                    .cornerRadius(4)
                
                // Tick marks (ruler-like appearance)
                HStack(spacing: 0) {
                    ForEach(0..<Int(maxSliderMinutes), id: \.self) { minute in
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.secondary.opacity(0.4))
                                .frame(width: 1, height: 8)
                        }
                        .frame(width: geometry.size.width / CGFloat(maxSliderMinutes))
                    }
                }
                .frame(height: 32)
                .allowsHitTesting(false)
                .drawingGroup()
                
                // Slider handle (vertical bar)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3, height: 32)
                    .cornerRadius(1.5)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(x: max(0, min(geometry.size.width - 3, (geometry.size.width - 3) * normalizedValue)))
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let rawValue = (value.location.x / geometry.size.width) * maxSliderMinutes
                        // Snap to 1-minute increments
                        let snappedValue = round(rawValue)
                        sliderValue = max(0, min(maxSliderMinutes, snappedValue))
                    }
                    .onEnded { _ in
                        isDragging = false
                        // Ensure final value is also snapped
                        sliderValue = round(sliderValue)
                        // Sync to minutes input
                        minutesInput = String(Int(sliderValue))
                    }
            )
        }
        .frame(height: 32)
    }
    
    // MARK: - Preset Buttons
    private var presetButtonsSection: some View {
        HStack(spacing: 12) {
            ForEach(settingsManager.presets.prefix(3)) { preset in
                Button(action: {
                    selectPreset(preset)
                }) {
                    Text(preset.displayName)
                        .font(.system(size: 11, weight: .light, design: .default))
                        .monospacedDigit()
                        .foregroundColor(.primary)
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
                    .font(.system(size: 11, weight: .light, design: .default))
                    .monospacedDigit()
                    .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 20)
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Left side: Task input and start button
            VStack(alignment: .leading, spacing: 8) {
                // Task description field
                TextField("Task description...", text: $taskDescription)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .frame(maxWidth: 140)
                    .focused($focusedField, equals: .task)
                    .onSubmit {
                        // Start timer, show floating display, and close popover
                        startTimer()
                        FloatingTimerWindowController.shared.show()
                        NotificationCenter.default.post(name: .closePopover, object: nil)
                    }
                
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
            if timerManager.state == .idle {
                // Editable time input when idle
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Spacer()
                    TextField("0", text: $minutesInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 42, weight: .light, design: .default))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: true, vertical: false)
                        .focused($focusedField, equals: .minutes)
                        .onChange(of: minutesInput) { _, newValue in
                            // Sync minutes input to slider value
                            if let minutes = Double(newValue) {
                                sliderValue = min(maxSliderMinutes, max(0, minutes))
                            }
                        }
                        .onSubmit {
                            // Move to task description on Enter
                            focusedField = .task
                        }
                    Text("m")
                        .font(.system(size: 28, weight: .light, design: .default))
                        .foregroundColor(.secondary)
                }
                .frame(width: 170, alignment: .trailing)
            } else {
                // Running timer display - click to stop and edit
                Text(timerManager.formattedTime)
                    .font(.system(size: 42, weight: .light, design: .default))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                    .frame(width: 170, alignment: .trailing)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Stop timer and enter edit mode
                        let currentMinutes = timerManager.timeRemaining / 60
                        timerManager.stopTimer()
                        minutesInput = String(currentMinutes)
                        sliderValue = Double(currentMinutes)
                        focusedField = .minutes
                    }
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            }
            
            // Timer controls (reserve space even when idle to prevent layout shifts)
            HStack(spacing: 12) {
                Button(action: {
                    timerManager.togglePauseResume()
                }) {
                    Image(systemName: timerManager.state == .running ? "pause" : "play")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(timerManager.state != .idle ? 1 : 0)
                
                Button(action: {
                    timerManager.stopTimer()
                    sliderValue = 0
                    minutesInput = ""
                }) {
                    Image(systemName: "stop")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(timerManager.state != .idle ? 1 : 0)
                
                Button(action: {
                    FloatingTimerWindowController.shared.toggle()
                }) {
                    Image(systemName: "pip")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle floating timer")
            }
        }
    }
    
    // MARK: - Computed Properties
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
        minutesInput = String(preset.minutes)
    }
}

extension Notification.Name {
    static let showFloatingWindow = Notification.Name("showFloatingWindow")
    static let showSettings = Notification.Name("showSettings")
    static let closePopover = Notification.Name("closePopover")
}

#Preview {
    MenuBarView()
}
