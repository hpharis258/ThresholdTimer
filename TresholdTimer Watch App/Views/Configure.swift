//
//  Configure.swift
//  TresholdTimer Watch App
//
//  Created by Haroldas Varanauskas on 11/10/2025.
//

import SwiftUI

struct Configure: View {
    @StateObject private var settings = AppSettings.shared
        @State private var newLabel = ""
        @State private var newDuration = 30.0
        @State private var threshold = UserDefaults.standard.double(forKey: "thresholdValue") == 0 ? 100 : UserDefaults.standard.double(forKey: "thresholdValue")

        var body: some View {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Timer Presets")
                        .font(.headline)

                    ForEach(settings.presets) { preset in
                        HStack {
                            Text("\(preset.label)")
                            Spacer()
                            Text("\(Int(preset.duration))s")
                        }
                    }

                    Divider()
                    
                    TextField("Label", text: $newLabel)
                    Slider(value: $newDuration, in: 10...600, step: 10)
                    Text("Duration: \(Int(newDuration))s")

                    Button("Add Preset") {
                        guard !newLabel.isEmpty else { return }
                        let preset = TimerPreset(label: newLabel, duration: newDuration)
                        settings.addPreset(preset)
                        newLabel = ""
                    }
                    
                    Divider()
                    
                    Text("Threshold: \(Int(threshold)) bpm")
                    Slider(value: $threshold, in: 40...200, step: 1)
                    Button("Save Threshold") {
                        UserDefaults.standard.set(threshold, forKey: "thresholdValue")
                    }
                }
                .padding()
            }
        }
}

#Preview {
    Configure()
}
