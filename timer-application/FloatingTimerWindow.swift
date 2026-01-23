//
//  FloatingTimerWindow.swift
//  timer-application
//

import SwiftUI
import AppKit

class FloatingTimerWindowController: NSWindowController {
    static let shared = FloatingTimerWindowController()
    
    private init() {
        let window = FloatingPanel()
        super.init(window: window)

        let hostingView = NSHostingView(rootView: FloatingTimerView())
        window.contentView = hostingView

        // Disable window animations
        window.animationBehavior = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        window?.orderFrontRegardless()
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }
}

class FloatingPanel: NSPanel {
    // Maintain aspect ratio during resize
    private let panelAspectRatio: CGFloat = 2.5 // width / height
    
    init() {
        let initialWidth: CGFloat = 160
        let initialHeight: CGFloat = 64
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight),
            styleMask: [.borderless, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // ALWAYS ON TOP - use statusBar level for highest priority
        level = .statusBar
        
        // Show on all Spaces and in fullscreen
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        // Don't hide when app is not active
        hidesOnDeactivate = false
        
        // Appearance
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        
        // Draggable
        isMovableByWindowBackground = true
        
        // Floating panel behavior
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        
        // Tighter resizable constraints - enforce aspect ratio
        minSize = NSSize(width: 120, height: 48)
        maxSize = NSSize(width: 320, height: 128)
        
        // Set aspect ratio constraint
        contentAspectRatio = NSSize(width: panelAspectRatio, height: 1)
        
        // Center on screen initially
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY - frame.height / 2
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    // Allow panel to become key window for text input
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}

struct FloatingTimerView: View {
    @ObservedObject var timerManager = TimerManager.shared
    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editMinutes: String = "05"
    @State private var editSeconds: String = "00"
    @State private var editTask: String = ""
    @State private var isHoveringTime = false
    
    // Base dimensions for scaling calculations
    private let baseWidth: CGFloat = 160
    private let baseHeight: CGFloat = 64
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate uniform scale factor based on height (since aspect ratio is locked)
            let scale = geometry.size.height / baseHeight
            let clampedScale = max(0.7, min(2.0, scale))
            
            // Scale fonts proportionally
            let timerFontSize: CGFloat = 32 * clampedScale
            let labelFontSize: CGFloat = 10 * clampedScale
            let buttonFontSize: CGFloat = 12 * clampedScale
            
            ZStack {
                // Background - pitch black with rounded corners like macOS pill style
                RoundedRectangle(cornerRadius: 16 * clampedScale)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16 * clampedScale)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                
                // Resize handle indicator (subtle)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 6))
                            .foregroundColor(.white.opacity(0.2))
                            .padding(6)
                    }
                }
                
                // Main content
                VStack(spacing: 4 * clampedScale) {
                    if isEditing {
                        editModeView(
                            timerFontSize: timerFontSize,
                            labelFontSize: labelFontSize,
                            scale: clampedScale
                        )
                    } else {
                        displayModeView(
                            timerFontSize: timerFontSize,
                            labelFontSize: labelFontSize,
                            buttonFontSize: buttonFontSize,
                            scale: clampedScale
                        )
                    }
                }
                .padding(.horizontal, 16 * clampedScale)
                .padding(.vertical, 10 * clampedScale)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
        }
    }
    
    @ViewBuilder
    private func editModeView(timerFontSize: CGFloat, labelFontSize: CGFloat, scale: CGFloat) -> some View {
        VStack(spacing: 4 * scale) {
            // Time input
            HStack(spacing: 2) {
                TextField("00", text: $editMinutes)
                    .textFieldStyle(.plain)
                    .font(.system(size: timerFontSize, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: timerFontSize * 1.5)
                    .padding(.vertical, 2 * scale)
                    .padding(.horizontal, 4 * scale)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6 * scale)
                    .onSubmit { startTimerFromEdit() }
                
                Text(":")
                    .font(.system(size: timerFontSize, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                
                TextField("00", text: $editSeconds)
                    .textFieldStyle(.plain)
                    .font(.system(size: timerFontSize, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: timerFontSize * 1.5)
                    .padding(.vertical, 2 * scale)
                    .padding(.horizontal, 4 * scale)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6 * scale)
                    .onSubmit { startTimerFromEdit() }
            }
            
            // Task input
            TextField("Task...", text: $editTask)
                .textFieldStyle(.plain)
                .font(.system(size: labelFontSize, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 2 * scale)
                .padding(.horizontal, 8 * scale)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4 * scale)
                .onSubmit { startTimerFromEdit() }
            
            // Action buttons
            HStack(spacing: 12 * scale) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isEditing = false
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: labelFontSize, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                
                Button(action: startTimerFromEdit) {
                    Text("Start")
                        .font(.system(size: labelFontSize, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func displayModeView(timerFontSize: CGFloat, labelFontSize: CGFloat, buttonFontSize: CGFloat, scale: CGFloat) -> some View {
        Group {
            if timerManager.state == .idle {
                // Idle state
                VStack(spacing: 2 * scale) {
                    Text("00:00")
                        .font(.system(size: timerFontSize, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .contentShape(Rectangle())
                        .onTapGesture { enterEditMode() }
                        .onHover { hovering in
                            isHoveringTime = hovering
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    
                    Text("Click to start")
                        .font(.system(size: labelFontSize, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
            } else {
                // Running/Paused state
                VStack(spacing: 2 * scale) {
                    Text(timerManager.formattedTime)
                        .font(.system(size: timerFontSize, weight: .light, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentShape(Rectangle())
                        .onTapGesture { enterEditMode() }
                        .onHover { hovering in
                            isHoveringTime = hovering
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    
                    // Task description
                    if !timerManager.taskDescription.isEmpty {
                        Text(timerManager.taskDescription)
                            .font(.system(size: labelFontSize, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    // Controls (shown on hover)
                    if isHovering {
                        HStack(spacing: 16 * scale) {
                            Button(action: { timerManager.togglePauseResume() }) {
                                Image(systemName: timerManager.state == .running ? "pause.fill" : "play.fill")
                                    .font(.system(size: buttonFontSize))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { timerManager.stopTimer() }) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: buttonFontSize))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { FloatingTimerWindowController.shared.hide() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: labelFontSize))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 2 * scale)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
        }
    }
    
    private func enterEditMode() {
        if timerManager.state != .idle {
            let minutes = timerManager.timeRemaining / 60
            let seconds = timerManager.timeRemaining % 60
            editMinutes = String(format: "%02d", minutes)
            editSeconds = String(format: "%02d", seconds)
            editTask = timerManager.taskDescription
        } else {
            editMinutes = "05"
            editSeconds = "00"
            editTask = ""
        }
        
        // Make the floating window key to accept text input while staying on top
        if let panel = NSApp.windows.first(where: { $0 is FloatingPanel }) as? FloatingPanel {
            panel.makeKeyAndOrderFront(nil)
            // Ensure it stays at statusBar level
            panel.level = .statusBar
        }
        
        withAnimation(.easeInOut(duration: 0.15)) {
            isEditing = true
        }
    }
    
    private func startTimerFromEdit() {
        let minutes = Int(editMinutes) ?? 0
        let seconds = Int(editSeconds) ?? 0
        
        guard minutes > 0 || seconds > 0 else {
            withAnimation(.easeInOut(duration: 0.15)) {
                isEditing = false
            }
            return
        }
        
        timerManager.startTimer(minutes: minutes, seconds: seconds, task: editTask)
        
        withAnimation(.easeInOut(duration: 0.15)) {
            isEditing = false
        }
    }
}

#Preview {
    FloatingTimerView()
        .frame(width: 160, height: 64)
}
