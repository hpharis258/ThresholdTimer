//
//  ContentView.swift
//  TresholdTimer Watch App
//
//  Created by Haroldas Varanauskas on 05/10/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
           NavigationStack {
               VStack(spacing: 12) {
                   NavigationLink(destination: Treshold()) {
                       TileView(title: "Threshold ", systemImage: "timer")
                   }

                   NavigationLink(destination: Manual()) {
                       TileView(title: "Manual", systemImage: "hand.point.up.left")
                   }
                   NavigationLink(destination: Configure()) {
                       TileView(title: "Configure ", systemImage: "gearshape")
                   }
               }
               .padding()
               .navigationTitle("Select Mode")
           }
       }
}

#Preview {
    ContentView()
}

struct TileView: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 24)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


