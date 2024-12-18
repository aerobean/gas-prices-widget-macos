//
//  ContentView.swift
//  Gas prices widget
//
//  Created by Max Max on 24.10.2024.
//

import SwiftUI
import GasPriceWidgetShared

struct ContentView: View {
    @State private var showingSettings = false
    @StateObject private var preferences = PreferencesObserver()
    
    var body: some View {
        NavigationSplitView {
            List {
                Button {
                    showingSettings.toggle()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                
                Text("Selected Unit: \(preferences.priceUnit.displaySymbol)")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Gas Prices Widget")
        } detail: {
            VStack {
                Image(systemName: "arrow.left")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Select an option from the sidebar")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
