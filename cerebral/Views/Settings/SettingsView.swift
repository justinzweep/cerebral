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
            
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(settingsManager)
            
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape.fill")
                }
                .environmentObject(settingsManager)
        }
        .frame(width: 500, height: 450)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
} 