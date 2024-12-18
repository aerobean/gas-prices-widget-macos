import SwiftUI
import WidgetKit
import GasPriceWidgetShared

struct SettingsView: View {
    @StateObject private var preferences = PreferencesObserver()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Widget Settings")
                .font(.title)
                .padding(.bottom, 10)
            
            Form {
                Section(header: Text("Update Frequency")) {
                    Picker("Update Every", selection: $preferences.updateFrequency) {
                        ForEach(UpdateFrequency.allCases, id: \.rawValue) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Price Unit")) {
                    Picker("Display Prices In", selection: $preferences.priceUnit) {
                        ForEach(PriceUnit.allCases, id: \.rawValue) { unit in
                            Text(unit.displaySymbol).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Done") {
                    WidgetCenter.shared.reloadAllTimelines()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

class PreferencesObserver: ObservableObject {
    @Published var updateFrequency: UpdateFrequency {
        didSet {
            UserPreferences.shared.updateFrequency = updateFrequency
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @Published var priceUnit: PriceUnit {
        didSet {
            UserPreferences.shared.priceUnit = priceUnit
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    init() {
        self.updateFrequency = UserPreferences.shared.updateFrequency
        self.priceUnit = UserPreferences.shared.priceUnit
    }
} 