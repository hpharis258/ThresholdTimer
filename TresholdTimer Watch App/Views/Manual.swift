import SwiftUI
import WatchKit
import Combine
import UserNotifications

struct Manual: View {
    @State private var timeRemaining: TimeInterval = 0
    @State private var timerRunning = false
    @State private var displayTimer: Timer?
    @State private var endDate: Date?
    @State private var selectedPreset: TimerPreset?

    @StateObject private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 12) {
            Picker("Select Timer", selection: $selectedPreset) {
                ForEach(settings.presets) { preset in
                    Text(preset.label).tag(Optional(preset))
                }
            }
            .frame(height: 50)
            .pickerStyle(.wheel)
            .disabled(timerRunning)
            .focusable(true)

            if timeRemaining > 0 {
                Text("\(Int(timeRemaining))s")
                    .font(.title)
                    .padding(.top, 10)
            } else {
                Text("Done!")
                    .font(.title2)
                    .foregroundColor(.green)
                    .padding(.top, 10)
            }

            Button(timerRunning ? "Stop" : "Start") {
                timerRunning ? stopTimer() : startTimer()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            if let first = settings.presets.first {
                if selectedPreset == nil {
                    selectedPreset = first
                    timeRemaining = first.duration
                }
            }
            // Ensure timeRemaining reflects any existing endDate
            updateRemaining()
            // Request notification permission (safe to call repeatedly)
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        .onChange(of: selectedPreset) { oldValue, newValue in
            if !timerRunning {
                timeRemaining = newValue?.duration ?? 30
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        guard let preset = selectedPreset else { return }
        stopTimer()
        let now = Date()
        endDate = now.addingTimeInterval(preset.duration)
        timerRunning = true

        // Schedule a lightweight UI refresh timer (not relied upon for correctness)
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            updateRemaining()
        }
        if let displayTimer = displayTimer {
            RunLoop.main.add(displayTimer, forMode: .common)
        }

        // Schedule local notification for completion
        if let endDate {
            scheduleCompletionNotification(at: endDate)
        }

        updateRemaining()
    }

    private func stopTimer() {
        timerRunning = false
        displayTimer?.invalidate()
        displayTimer = nil
        endDate = nil
        cancelCompletionNotification()
        // Reset timeRemaining to selected preset for quick restart
        if let preset = selectedPreset {
            timeRemaining = preset.duration
        }
    }

    private func updateRemaining() {
        if let endDate {
            let remaining = endDate.timeIntervalSinceNow
            if remaining > 0 {
                timeRemaining = remaining
            } else {
                timeRemaining = 0
                finishTimer()
            }
        } else {
            // No active timer; keep current preset duration if available
            if let preset = selectedPreset {
                timeRemaining = min(timeRemaining, preset.duration)
            }
        }
    }

    private func finishTimer() {
        // Clean up UI timer and state but keep last selected preset
        timerRunning = false
        displayTimer?.invalidate()
        displayTimer = nil
        endDate = nil

        WKInterfaceDevice.current().play(.notification)
        // Reset to preset duration for quick restart
        if let preset = selectedPreset {
            timeRemaining = preset.duration
        }
    }

    private func scheduleCompletionNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Done"
        content.body = selectedPreset?.label ?? "Your timer has finished."
        content.sound = .default

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "manual-timer-complete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["manual-timer-complete"])
    }
}

#Preview {
    Manual()
}
