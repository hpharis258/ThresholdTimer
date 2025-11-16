import SwiftUI
import WatchKit
import Combine

struct Manual: View {
    @State private var timeRemaining: TimeInterval = 0
    @State private var timerRunning = false
    @State private var timer: Timer?
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
                selectedPreset = first
                timeRemaining = first.duration
            }
        }
        .onChange(of: selectedPreset) { oldValue, newValue in
            timeRemaining = newValue?.duration ?? 30
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        guard let preset = selectedPreset else { return }
        timeRemaining = preset.duration
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                WKInterfaceDevice.current().play(.notification)
                timeRemaining = preset.duration // reset for quick restart
            }
        }
    }
    
    private func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    Manual()
}
