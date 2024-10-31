#if WIDGET
import WidgetKit
#endif
import Foundation

/// Represents possible network-related errors that can occur during API requests
public enum NetworkError: Error, CustomStringConvertible {
    case invalidURL
    case invalidResponse(Int)
    case decodingError(String)
    case apiError(String)
    case timeout
    
    public var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse(let statusCode):
            return "Invalid response (Status: \(statusCode))"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .timeout:
            return "Request timed out"
        }
    }
}

/// Manages network requests for cryptocurrency gas prices and fees
public class NetworkManager {
    /// Shared singleton instance
    public static let shared = NetworkManager()
    private let session: URLSession
    
    private init() {
        // Configure URLSession for optimal widget performance
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 10
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        
        #if os(macOS)
        // macOS-specific optimizations
        config.networkServiceType = .background
        config.shouldUseExtendedBackgroundIdleMode = true
        #endif
        
        self.session = URLSession(configuration: config)
    }

    /// Fetches current gas prices for all supported cryptocurrencies
    /// - Returns: Combined gas prices for ETH, BTC, and SOL
    /// - Throws: NetworkError if any request fails
    public func fetchAllPrices() async throws -> GasPrices {
        return try await Task.detached(priority: .userInitiated) {
            async let ethPrice = self.fetchEthGasPrice()
            async let btcPrice = self.fetchBtcFee()
            async let solPrice = self.fetchSolGas()
            
            do {
                let (eth, btc, sol) = try await (ethPrice, btcPrice, solPrice)
                return GasPrices(ethGas: eth, btcFee: btc, solGas: sol)
            } catch {
                print("Fetch error: \(error.localizedDescription)")
                throw error
            }
        }.value
    }
    
    /// Fetches current Ethereum gas prices from Etherscan API
    /// - Returns: Current gas prices in gwei
    /// - Throws: NetworkError if request fails
    private func fetchEthGasPrice() async throws -> GasPrice {
        let urlString = "https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey=\(Config.etherscanApiKey)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let request = createURLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(-1)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(EtherscanResponse.self, from: data)
        return result.result.gasPrice
    }
    
    /// Fetches current Bitcoin transaction fees from mempool.space
    /// - Returns: Current fees in sat/vB
    /// - Throws: NetworkError if request fails
    private func fetchBtcFee() async throws -> BtcFee {
        let urlString = "https://mempool.space/api/v1/fees/recommended"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let request = createURLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(-1)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(MempoolResponse.self, from: data)
        return result.btcFee
    }
    
    /// Fetches current Solana price from CoinGecko
    /// - Returns: Current SOL price in USD
    /// - Throws: NetworkError if request fails
    private func fetchSolGas() async throws -> SolPrice {
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let request = createURLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(-1)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(httpResponse.statusCode)
        }
        
        struct CoinGeckoResponse: Codable {
            let solana: SolanaPrice
            
            struct SolanaPrice: Codable {
                let usd: Double
            }
        }
        
        let result = try JSONDecoder().decode(CoinGeckoResponse.self, from: data)
        return SolPrice(current: result.solana.usd)
    }
    
    /// Creates a configured URLRequest with standard parameters
    private func createURLRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.networkServiceType = .responsiveData
        return request
    }
}
