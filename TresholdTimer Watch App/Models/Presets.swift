//
//  Presets.swift
//  TresholdTimer
//
//  Created by Haroldas Varanauskas on 11/10/2025.
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private init() {
        loadPresets()
    }
    
    @Published var presets: [TimerPreset] = []
    
    func addPreset(_ preset: TimerPreset) {
        presets.append(preset)
        savePresets()
    }
    
    func removePreset(_ preset: TimerPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }
    
    private func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: "timerPresets")
        }
    }
    
    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: "timerPresets"),
              let saved = try? JSONDecoder().decode([TimerPreset].self, from: data) else {
            // Default values
            presets = [
                TimerPreset(label: "30 sec", duration: 30),
                TimerPreset(label: "1 min", duration: 60),
                TimerPreset(label: "2 min", duration: 120)
            ]
            return
        }
        presets = saved
    }
}
