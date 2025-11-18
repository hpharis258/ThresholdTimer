//
//  Configure.swift
//  TresholdTimer Watch App
//
//  Created by Haroldas Varanauskas on 11/10/2025.
//

import SwiftUI
import Foundation

struct Configure: View {
    @StateObject private var settings = AppSettings.shared
    @State private var newLabel = ""
    @State private var newDuration = 30.0
    @AppStorage("thresholdValue") private var threshold: Double = 100
    
    private let presetsKey = "timerPresets"

    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: presetsKey) {
            do {
                let decoded = try JSONDecoder().decode([TimerPreset].self, from: data)
                // Update settings on main thread
                DispatchQueue.main.async {
                    settings.presets = decoded
                }
            } catch {
                // Ignore decode errors for now
            }
        }
    }

    private func savePresets() {
        do {
            let data = try JSONEncoder().encode(settings.presets)
            debugPrint(data);
            UserDefaults.standard.set(data, forKey: presetsKey)
        } catch {
            // Ignore encode errors for now
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Timer Presets")
                    .font(.headline)

                ForEach(settings.presets) { preset in
                    HStack {
                        Text(preset.label)
                        Spacer()
                        Text("\(Int(preset.duration))s")
                    }
                }
                .onDelete { indexSet in
                    settings.presets.remove(atOffsets: indexSet)
                    savePresets()
                }

                Divider()
                
                TextField("Label", text: $newLabel)
                Slider(value: $newDuration, in: 1...600, step: 1)
                Text("Duration: \(Int(newDuration))s")

                Button("Add Preset") {
                    guard !newLabel.isEmpty else { return }
                    let preset = TimerPreset(label: newLabel, duration: newDuration)
                    settings.addPreset(preset)
                    savePresets()
                    newLabel = ""
                }
                
                Divider()
                
                Text("Threshold: \(Int(threshold)) bpm")
                Slider(value: $threshold, in: 40...200, step: 1)
            }
            .padding()
        }
        .onAppear {
            loadPresets()
        }
    }
}

#Preview {
    Configure()
}
