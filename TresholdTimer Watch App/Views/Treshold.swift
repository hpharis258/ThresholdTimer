import SwiftUI
import WatchKit

struct Treshold: View {
    @StateObject private var heartMonitor = HeartRateMonitor.shared
    @State private var isRunning = false
    @State private var isAuthorized = false
    @AppStorage("thresholdValue") private var threshold: Double = 100
    @State private var hapticTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text("Heart Rate: \(Int(heartMonitor.currentHeartRate)) bpm")
                .font(.headline)
            
            Text("Threshold: \(Int(threshold)) bpm")
                .font(.caption)

            Button(isRunning ? "Stop" : "Start") {
                toggleMonitoring()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isAuthorized)
        }
        .task {
            // Request authorization using a synchronous API and update UI state on the main actor.
            heartMonitor.requestAuthorization()
            await MainActor.run { isAuthorized = true }
        }
        .onChange(of: heartMonitor.currentHeartRate) { oldValue, newValue in
            if isRunning && newValue < threshold {
                startHapticsIfNeeded()
            } else {
                stopHaptics()
            }
        }
        .onDisappear {
            stopHaptics()
        }
    }
    
    private func startHapticsIfNeeded() {
        // If already running, do nothing
        guard hapticTask == nil else { return }
        // Only start if monitoring is on and condition is met
        guard isRunning, heartMonitor.currentHeartRate < threshold else { return }
        hapticTask = Task {
            while !Task.isCancelled {
                // Play a simple, repeatable haptic
                WKInterfaceDevice.current().play(.notification)
                // Sleep for a short interval to avoid spamming
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                // Check condition safely on the main actor
                let shouldContinue = await MainActor.run {
                    isRunning && heartMonitor.currentHeartRate < threshold
                }
                if !shouldContinue {
                    // Debounce transient changes before stopping
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                    let recheck = await MainActor.run {
                        isRunning && heartMonitor.currentHeartRate < threshold
                    }
                    if !recheck { break }
                }
            }
            // Cleanup when loop exits
            await MainActor.run { hapticTask = nil }
        }
    }

    private func stopHaptics() {
        hapticTask?.cancel()
        hapticTask = nil
    }

    private func toggleMonitoring() {
        if isRunning {
            // Stopping
            isRunning = false
            heartMonitor.stopMonitoring()
            stopHaptics()
            WKInterfaceDevice.current().play(.click)
        } else {
            // Starting
            isRunning = true
            heartMonitor.startMonitoring()
            // Evaluate immediately in case HR is already below threshold
            startHapticsIfNeeded()
            WKInterfaceDevice.current().play(.start)
        }
    }
}
