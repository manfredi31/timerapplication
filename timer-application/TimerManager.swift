//
//  TimerManager.swift
//  timer-application
//

import Foundation
import Combine
import UserNotifications
import AVFoundation
import AppKit

enum TimerState {
    case idle
    case running
    case paused
}

class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    @Published var timeRemaining: Int = 0
    @Published var totalTime: Int = 0
    @Published var state: TimerState = .idle
    @Published var taskDescription: String = ""
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var isPlayingAlarm = false
    
    var formattedTime: String {
        let totalSeconds = timeRemaining
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var menuBarDisplay: String {
        if state == .idle {
            return "⏱"
        }
        
        let timeStr = formattedTime
        if taskDescription.isEmpty {
            return timeStr
        }
        
        // Truncate task description if too long
        let maxLength = 15
        let truncatedTask = taskDescription.count > maxLength 
            ? String(taskDescription.prefix(maxLength)) + "…"
            : taskDescription
        
        return "\(timeStr) · \(truncatedTask)"
    }
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }
    
    init() {
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func startTimer(minutes: Int, seconds: Int = 0, task: String = "") {
        // Stop any existing timer
        stopTimer()
        
        totalTime = minutes * 60 + seconds
        timeRemaining = totalTime
        taskDescription = task
        state = .running
        
        startTimerLoop()
    }
    
    func startTimerFromSeconds(_ totalSeconds: Int, task: String = "") {
        stopTimer()
        
        totalTime = totalSeconds
        timeRemaining = totalSeconds
        taskDescription = task
        state = .running
        
        startTimerLoop()
    }
    
    private func startTimerLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timerFinished()
            }
        }
    }
    
    func pauseTimer() {
        guard state == .running else { return }
        timer?.invalidate()
        timer = nil
        state = .paused
    }
    
    func resumeTimer() {
        guard state == .paused else { return }
        state = .running
        startTimerLoop()
    }
    
    func togglePauseResume() {
        switch state {
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        case .idle:
            break
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        stopAlarm()
        state = .idle
        timeRemaining = 0
        totalTime = 0
        taskDescription = ""
    }
    
    private func timerFinished() {
        timer?.invalidate()
        timer = nil
        
        // Play alarm
        playAlarm()
        
        // Send notification
        sendNotification()
    }
    
    private func playAlarm() {
        isPlayingAlarm = true
        let selectedSound = SettingsManager.shared.selectedAlarmSound
        
        // Try to play the selected sound
        if let soundURL = Bundle.main.url(forResource: selectedSound, withExtension: "wav") ??
                          Bundle.main.url(forResource: selectedSound, withExtension: "mp3") ??
                          Bundle.main.url(forResource: selectedSound, withExtension: "aiff") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = 2
                audioPlayer?.play()
                
                // Auto-clear after alarm finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 3) * 3) {
                    self.clearAfterAlarm()
                }
            } catch {
                playSystemSound()
            }
        } else {
            playSystemSound()
        }
    }
    
    private func playSystemSound() {
        // Play system sound as fallback
        NSSound.beep()
        
        // Create a repeated beep effect
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                if self.isPlayingAlarm {
                    NSSound.beep()
                }
            }
        }
        
        // Auto-clear after beeps
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.clearAfterAlarm()
        }
    }
    
    func stopAlarm() {
        isPlayingAlarm = false
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    private func clearAfterAlarm() {
        stopAlarm()
        state = .idle
        timeRemaining = 0
        totalTime = 0
        taskDescription = ""
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Finished!"
        content.body = taskDescription.isEmpty ? "Your timer has completed." : "Task completed: \(taskDescription)"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

