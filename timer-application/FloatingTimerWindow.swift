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
    init() {
        let initialWidth: CGFloat = 160
        let initialHeight: CGFloat = 64
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight),
            styleMask: [.borderless, .utilityWindow, .nonactivatingPanel],
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
        
        // Draggable by background
        isMovableByWindowBackground = true
        
        // Floating panel behavior - non-interactive
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        ignoresMouseEvents = false  // Still allow dragging
        
        // Center on screen initially
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY - frame.height / 2
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}

struct FloatingTimerView: View {
    @ObservedObject var timerManager = TimerManager.shared
    
    // Base dimensions for scaling calculations
    private let baseHeight: CGFloat = 64
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate uniform scale factor based on height (since aspect ratio is locked)
            let scale = geometry.size.height / baseHeight
            let clampedScale = max(0.7, min(2.0, scale))
            
            // Scale fonts proportionally
            let timerFontSize: CGFloat = 32 * clampedScale
            let labelFontSize: CGFloat = 10 * clampedScale
            
            ZStack {
                // Background - pitch black with rounded corners like macOS pill style
                RoundedRectangle(cornerRadius: 16 * clampedScale)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16 * clampedScale)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                
                // Main content - just timer and task description
                VStack(spacing: 2 * clampedScale) {
                    Text(timerManager.state == .idle ? "00:00" : timerManager.formattedTime)
                        .font(.system(size: timerFontSize, weight: .light, design: .rounded))
                        .foregroundColor(timerManager.state == .idle ? .white.opacity(0.5) : .white)
                        .monospacedDigit()
                    
                    // Task description (only show if not empty)
                    if !timerManager.taskDescription.isEmpty {
                        Text(timerManager.taskDescription)
                            .font(.system(size: labelFontSize, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.horizontal, 16 * clampedScale)
                .padding(.vertical, 10 * clampedScale)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    FloatingTimerView()
        .frame(width: 160, height: 64)
}
