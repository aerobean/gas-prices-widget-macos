import Foundation
import WidgetKit

public enum UpdateFrequency: String, CaseIterable {
    case fiveMinutes = "5 minutes"
    case tenMinutes = "10 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    
    public var minutes: Int {
        switch self {
        case .fiveMinutes: return 5
        case .tenMinutes: return 10
        case .fifteenMinutes: return 15
        case .thirtyMinutes: return 30
        }
    }
}

public enum PriceUnit: String, CaseIterable {
    case native = "Native Units"
    case usd = "$"
    
    public var displaySymbol: String {
        switch self {
        case .native: return "Native"
        case .usd: return "$"
        }
    }
    
    public func format(_ price: Double, for crypto: CryptoType) -> String {
        switch self {
        case .usd:
            return String(format: "$%.2f", price)
        case .native:
            switch crypto {
            case .ethereum:
                return String(format: "%.0f gwei", price)
            case .bitcoin:
                return String(format: "%.1f sat/vB", price)
            case .solana:
                return String(format: "%.0f tx/s", price)
            }
        }
    }
}

public enum CryptoType {
    case ethereum
    case bitcoin
    case solana
}

public class UserPreferences {
    public static var shared = UserPreferences()
    
    private let containerURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let bundleId = "gas-prices-widget"
        let appFolder = appSupport.appendingPathComponent(bundleId)
        
        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        
        return appFolder.appendingPathComponent("settings.plist")
    }()
    
    private func readSettings() -> [String: String] {
        print("Reading settings from: \(containerURL.path)")
        do {
            let data = try Data(contentsOf: containerURL)
            let settings = try PropertyListDecoder().decode([String: String].self, from: data)
            print("Successfully read settings: \(settings)")
            return settings
        } catch {
            print("Error reading settings: \(error)")
            return [:]
        }
    }
    
    private func writeSettings(_ settings: [String: String]) {
        print("Writing settings: \(settings)")
        do {
            let data = try PropertyListEncoder().encode(settings)
            try data.write(to: containerURL)
            print("Successfully wrote settings")
        } catch {
            print("Error writing settings: \(error)")
        }
    }
    
    public var updateFrequency: UpdateFrequency {
        get {
            let settings = readSettings()
            guard let value = settings["updateFrequency"],
                  let frequency = UpdateFrequency(rawValue: value)
            else {
                return .tenMinutes
            }
            return frequency
        }
        set {
            var settings = readSettings()
            settings["updateFrequency"] = newValue.rawValue
            writeSettings(settings)
        }
    }
    
    public var priceUnit: PriceUnit {
        get {
            let settings = readSettings()
            guard let value = settings["priceUnit"],
                  let unit = PriceUnit(rawValue: value)
            else {
                print("Using default price unit: native")
                return .native
            }
            print("Reading price unit: \(unit)")
            return unit
        }
        set {
            var settings = readSettings()
            settings["priceUnit"] = newValue.rawValue
            writeSettings(settings)
            print("Saved new price unit: \(newValue)")
        }
    }
} 