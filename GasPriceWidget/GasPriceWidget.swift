import WidgetKit
import SwiftUI
import GasPriceWidgetShared
import os

// Define logger at file level
private let widgetLogger = Logger(
    subsystem: "gas-prices-widget.extension",
    category: "Widget"
)

// MARK: - Widget Provider

/// Provides timeline entries for the widget
struct Provider: TimelineProvider {
    typealias Entry = GasPriceEntry
    
    func placeholder(in context: Context) -> GasPriceEntry {
        GasPriceEntry(
            date: Date(),
            ethGas: GasPrice(safeLow: 0, standard: 0, fast: 0),
            btcFee: BtcFee(fastestFee: 0, halfHourFee: 0, hourFee: 0),
            solGas: SolPrice(current: 0),
            state: .loading
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GasPriceEntry) -> Void) {
        Task {
            do {
                let prices = try await NetworkManager.shared.fetchAllPrices()
                let entry = GasPriceEntry(
                    date: Date(),
                    ethGas: prices.ethGas,
                    btcFee: prices.btcFee,
                    solGas: prices.solGas,
                    state: .success
                )
                completion(entry)
            } catch {
                completion(GasPriceEntry(
                    date: Date(),
                    ethGas: GasPrice(safeLow: 0, standard: 0, fast: 0),
                    btcFee: BtcFee(fastestFee: 0, halfHourFee: 0, hourFee: 0),
                    solGas: SolPrice(current: 0),
                    state: .error(error.localizedDescription)
                ))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GasPriceEntry>) -> ()) {
        widgetLogger.debug("Starting timeline fetch...")
        Task {
            do {
                widgetLogger.debug("Fetching prices...")
                let prices = try await NetworkManager.shared.fetchAllPrices()
                widgetLogger.debug("Prices fetched successfully")
                
                let entry = GasPriceEntry(
                    date: Date(),
                    ethGas: prices.ethGas,
                    btcFee: prices.btcFee,
                    solGas: prices.solGas,
                    state: .success
                )
                
                let nextUpdate = Date().addingTimeInterval(600)
                widgetLogger.debug("Next update scheduled for: \(nextUpdate.description)")
                
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                widgetLogger.error("Error fetching prices: \(error.localizedDescription)")
                let entry = GasPriceEntry(
                    date: Date(),
                    ethGas: GasPrice(safeLow: 0, standard: 0, fast: 0),
                    btcFee: BtcFee(fastestFee: 0, halfHourFee: 0, hourFee: 0),
                    solGas: SolPrice(current: 0),
                    state: .error(error.localizedDescription)
                )
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
                completion(timeline)
            }
        }
    }
}

// MARK: - Widget State and Entry

/// Represents the current state of the widget
enum WidgetState {
    case loading
    case success
    case error(String)
}

/// Timeline entry containing all data needed to render the widget
struct GasPriceEntry: TimelineEntry {
    let date: Date
    let ethGas: GasPrice
    let btcFee: BtcFee
    let solGas: SolPrice
    let state: WidgetState
}

// MARK: - Widget Views

/// Main entry view for the widget
struct GasPriceWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var body: some View {
        Group {
            switch entry.state {
            case .loading:
                LoadingView()
            case .error(let message):
                ErrorView(message: message)
            case .success:
                PricesView(entry: entry)
            }
        }
    }
}

/// View displaying all cryptocurrency prices
struct PricesView: View {
    @Environment(\.colorScheme) var colorScheme
    var entry: GasPriceEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "fuelpump.square.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .blue)
                    .font(.system(size: 14))
                Text("Gas Prices")
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(.top, 2)
            
            VStack(spacing: 8) {
                let priceUnit = UserPreferences.shared.priceUnit
                
                CryptoRow(
                    symbol: "₿",
                    price: priceUnit.format(entry.btcFee.displayPrice, for: .bitcoin),
                    unit: "sat/vB"
                )
                
                CryptoRow(
                    symbol: "Ξ",
                    price: priceUnit.format(entry.ethGas.displayPrice, for: .ethereum),
                    unit: "gwei"
                )
                
                CryptoRow(
                    symbol: "◎",
                    price: priceUnit.format(entry.solGas.displayPrice, for: .solana),
                    unit: "SOL"
                )
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct CryptoRow: View {
    let symbol: String
    let price: String
    let unit: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 24)
            
            Text(price)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(unit)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .font(.caption)
        }
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
            Text("Error")
                .font(.caption.bold())
            Text(message)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
    }
}

// MARK: - Widget Configuration

@main
struct GasPriceWidget: Widget {
    let kind: String = "GasPriceWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Group {
                switch entry.state {
                case .loading:
                    LoadingView()
                case .success:
                    if #available(macOS 14.0, *) {
                        PricesView(entry: entry)
                            .containerBackground(.background, for: .widget)
                    } else {
                        PricesView(entry: entry)
                            .padding()
                            .background()
                    }
                case .error(let message):
                    ErrorView(message: message)
                }
            }
        }
        .configurationDisplayName("Gas Prices")
        .description("Shows current gas prices for BTC, ETH, and SOL")
        .supportedFamilies([.systemSmall])
    }
}
