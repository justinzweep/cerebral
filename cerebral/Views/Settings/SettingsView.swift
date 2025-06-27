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
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .environmentObject(settingsManager)
            // PreferencesTabView()
            //     .tabItem {
            //         Label("Preferences", systemImage: "gearshape")
            //     }
            
            // AboutTabView()
            //     .tabItem {
            //         Label("About", systemImage: "info.circle")
            //     }
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
} 