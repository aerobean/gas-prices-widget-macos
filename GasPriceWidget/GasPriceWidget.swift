import WidgetKit
import SwiftUI
import GasPriceWidgetShared

// MARK: - Widget Provider

/// Provides timeline entries for the widget
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> GasPriceEntry {
        GasPriceEntry(
            date: Date(),
            ethGas: GasPrice(safeLow: 30, standard: 45, fast: 60),
            btcFee: BtcFee(fastestFee: 15, halfHourFee: 12, hourFee: 10),
            solGas: SolPrice(current: 0.00025),
            state: .success
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GasPriceEntry) -> ()) {
        Task {
            let entry = try? await fetchEntry()
            completion(entry ?? placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            do {
                let entry = try await fetchEntry()
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
                let timeline = Timeline(
                    entries: [entry],
                    policy: .after(nextUpdate)
                )
                completion(timeline)
            } catch {
                print("Timeline error: \(error.localizedDescription)")
                let errorEntry = GasPriceEntry(
                    date: Date(),
                    ethGas: GasPrice(safeLow: 0, standard: 0, fast: 0),
                    btcFee: BtcFee(fastestFee: 0, halfHourFee: 0, hourFee: 0),
                    solGas: SolPrice(current: 0),
                    state: .error(error.localizedDescription)
                )
                let nextRetry = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
                let timeline = Timeline(entries: [errorEntry], policy: .after(nextRetry))
                completion(timeline)
            }
        }
    }
    
    private func fetchEntry() async throws -> GasPriceEntry {
        do {
            let prices = try await NetworkManager.shared.fetchAllPrices()
            return GasPriceEntry(
                date: Date(),
                ethGas: prices.ethGas,
                btcFee: prices.btcFee,
                solGas: prices.solGas,
                state: .success
            )
        } catch {
            print("Network error: \(error.localizedDescription)")
            throw error
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

/// View displaying all cryptocurrency prices
struct PricesView: View {
    @Environment(\.colorScheme) var colorScheme
    var entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Gas Prices")
                .font(.system(size: 16, weight: .bold))
                .padding(.top, 2)
            
            VStack(spacing: 8) {
                CryptoRow(
                    symbol: "₿", // Bitcoin symbol
                    price: entry.btcFee.displayPrice,
                    unit: "sat/vB"
                )
                
                CryptoRow(
                    symbol: "Ξ", // Ethereum symbol
                    price: entry.ethGas.displayPrice,
                    unit: "gwei"
                )
                
                CryptoRow(
                    symbol: "◎", // Solana symbol
                    price: entry.solGas.displayPrice,
                    unit: "USD"
                )
            }
            .padding(.horizontal, 8)
            
            Text(entry.date, style: .time)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct CryptoRow: View {
    let symbol: String
    let price: Double
    let unit: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 24)
            
            Text(formattedPrice)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(unit)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var formattedPrice: String {
        if price < 10 {
            return String(format: "%.2f", price)
        } else if price < 100 {
            return String(format: "%.1f", price)
        } else {
            return String(format: "%.0f", price)
        }
    }
}

struct LoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct ErrorView: View {
    var message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16))
            
            Text("Error")
                .font(.system(size: 14, weight: .bold))
            
            Text(message)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .foregroundColor(.red)
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

// MARK: - Widget Configuration

@main
struct GasPriceWidget: Widget {
    let kind: String = "GasPriceWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            GasPriceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Crypto Gas Prices")
        .description("Track ETH, BTC, and SOL gas prices")
        .supportedFamilies([.systemSmall])
    }
}
