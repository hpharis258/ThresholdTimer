//
//  TimerPreset.swift
//  TresholdTimer Watch App
//
//  Created by Haroldas Varanauskas on 11/10/2025.
//

import Foundation

struct TimerPreset: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var label: String
    var duration: TimeInterval // in seconds
}
