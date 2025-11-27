import SwiftUI
import WatchKit

struct Treshold: View {
    @StateObject private var heartMonitor = HeartRateMonitor.shared
    @State private var isRunning = false
    @State private var isAuthorized = false
    @AppStorage("thresholdValue") private var threshold: Double = 100

    @AppStorage("beepIntervalSeconds") private var beepIntervalSeconds: Double = 1.0

    private var clampedBeepInterval: UInt64 {
        // Clamp between 1 and 10 seconds, convert to nanoseconds
        let seconds = min(max(beepIntervalSeconds, 1.0), 10.0)
        return UInt64(seconds * 1_000_000_000)
    }
    
    @State private var hapticTask: Task<Void, Never>? = nil
    @State private var runtimeSession: WKExtendedRuntimeSession? = nil

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
            stopExtendedRuntimeIfNeeded()
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
                try? await Task.sleep(nanoseconds: clampedBeepInterval)
                // Check condition safely on the main actor
                let shouldContinue = await MainActor.run {
                    isRunning && heartMonitor.currentHeartRate < threshold
                }
                if !shouldContinue {
                    // Debounce transient changes before stopping
                    let debounce = max(clampedBeepInterval / 2, UInt64(300_000_000))
                    try? await Task.sleep(nanoseconds: debounce)
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
            stopExtendedRuntimeIfNeeded()
            WKInterfaceDevice.current().play(.click)
        } else {
            // Starting
            isRunning = true
            startExtendedRuntimeIfNeeded()
            heartMonitor.startMonitoring()
            // Evaluate immediately in case HR is already below threshold
            startHapticsIfNeeded()
            WKInterfaceDevice.current().play(.start)
        }
    }
    
    // MARK: - Extended Runtime Session Management
    private func startExtendedRuntimeIfNeeded() {
        guard runtimeSession == nil else { return }
        let session = WKExtendedRuntimeSession()
        session.delegate = ExtendedRuntimeDelegate(onInvalidate: {
            // When the session ends or is invalidated, stop haptics to avoid a stuck loop
            Task { @MainActor in
                stopHaptics()
                isRunning = false
                heartMonitor.stopMonitoring()
            }
        })
        runtimeSession = session
        session.start()
    }

    private func stopExtendedRuntimeIfNeeded() {
        runtimeSession?.invalidate()
        runtimeSession = nil
    }
}

final class ExtendedRuntimeDelegate: NSObject, WKExtendedRuntimeSessionDelegate {
    private let onInvalidate: () -> Void

    init(onInvalidate: @escaping () -> Void) {
        self.onInvalidate = onInvalidate
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // No-op
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        onInvalidate()
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        onInvalidate()
    }
}
