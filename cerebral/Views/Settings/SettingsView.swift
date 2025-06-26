//
//  SettingsView.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        TabView {
            APIKeySettingsView()
                .tabItem {
                    Label("API Key", systemImage: "key.fill")
                }
                .environmentObject(settingsManager)
        }
        .frame(width: 500, height: 400)
        .navigationTitle("Preferences")
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
} 