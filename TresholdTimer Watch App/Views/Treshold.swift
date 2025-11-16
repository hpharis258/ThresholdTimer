import SwiftUI
import WatchKit

struct Treshold: View {
    @StateObject private var heartMonitor = HeartRateMonitor.shared
    @State private var isRunning = false
    @State private var threshold: Double = UserDefaults.standard.double(forKey: "thresholdValue") == 0 ? 100 : UserDefaults.standard.double(forKey: "thresholdValue")

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
        }
        .onAppear {
            // ✅ just call the method from the helper
            heartMonitor.requestAuthorization()
        }
        .onChange(of: heartMonitor.currentHeartRate) { oldValue, newValue in
            if isRunning && newValue < threshold {
                WKInterfaceDevice.current().play(.notification)
            }
        }
    }
    
    private func toggleMonitoring() {
        if isRunning {
            heartMonitor.stopMonitoring()
        } else {
            heartMonitor.startMonitoring()
        }
        isRunning.toggle()
    }
}

