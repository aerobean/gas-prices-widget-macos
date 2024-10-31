#if WIDGET
import WidgetKit
#endif
import Foundation

// MARK: - Core Data Models

/// Combined gas prices for all supported cryptocurrencies
public struct GasPrices {
    public let ethGas: GasPrice
    public let btcFee: BtcFee
    public let solGas: SolPrice
    
    public init(ethGas: GasPrice, btcFee: BtcFee, solGas: SolPrice) {
        self.ethGas = ethGas
        self.btcFee = btcFee
        self.solGas = solGas
    }
}

/// Ethereum gas price information
public struct GasPrice {
    public let safeLow: Double    // Low priority transaction price
    public let standard: Double   // Standard transaction price
    public let fast: Double       // High priority transaction price
    
    /// Price to display in the widget (using standard price)
    public var displayPrice: Double {
        return standard
    }
    
    public init(safeLow: Double, standard: Double, fast: Double) {
        self.safeLow = safeLow
        self.standard = standard
        self.fast = fast
    }
}

public struct BtcFee {
    public let fastestFee: Double
    public let halfHourFee: Double
    public let hourFee: Double
    
    public var displayPrice: Double {
        return halfHourFee
    }
    
    public init(fastestFee: Double, halfHourFee: Double, hourFee: Double) {
        self.fastestFee = fastestFee
        self.halfHourFee = halfHourFee
        self.hourFee = hourFee
    }
}

public struct SolPrice {
    public let current: Double
    
    public var displayPrice: Double {
        return current
    }
    
    public init(current: Double) {
        self.current = current
    }
}

// MARK: - API Response Models

/// Response structure for Etherscan API
public struct EtherscanResponse: Codable {
    public let status: String
    public let message: String
    public let result: EthGasResult
    
    public init(status: String, message: String, result: EthGasResult) {
        self.status = status
        self.message = message
        self.result = result
    }
}

public struct EthGasResult: Codable {
    public let SafeGasPrice: String
    public let ProposeGasPrice: String
    public let FastGasPrice: String
    
    public var gasPrice: GasPrice {
        GasPrice(
            safeLow: Double(SafeGasPrice) ?? 0,
            standard: Double(ProposeGasPrice) ?? 0,
            fast: Double(FastGasPrice) ?? 0
        )
    }
    
    public init(SafeGasPrice: String, ProposeGasPrice: String, FastGasPrice: String) {
        self.SafeGasPrice = SafeGasPrice
        self.ProposeGasPrice = ProposeGasPrice
        self.FastGasPrice = FastGasPrice
    }
}

public struct MempoolResponse: Codable {
    public let fastestFee: Int
    public let halfHourFee: Int
    public let hourFee: Int
    
    public var btcFee: BtcFee {
        BtcFee(
            fastestFee: Double(fastestFee),
            halfHourFee: Double(halfHourFee),
            hourFee: Double(hourFee)
        )
    }
    
    public init(fastestFee: Int, halfHourFee: Int, hourFee: Int) {
        self.fastestFee = fastestFee
        self.halfHourFee = halfHourFee
        self.hourFee = hourFee
    }
}

public struct SolscanResponse: Codable {
    public let success: Bool
    public let result: SolResult
    
    public init(success: Bool, result: SolResult) {
        self.success = success
        self.result = result
    }
}

public struct SolResult: Codable {
    public let price: Double
    
    public var solPrice: SolPrice {
        SolPrice(current: price)
    }
    
    public init(price: Double) {
        self.price = price
    }
}
