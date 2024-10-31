//
//  README.md
//  Crypto Gas Price Widget


# Features

- Real-time gas price updates for multiple networks
- Clean, minimalist design
- Dark and light mode support
- Automatic updates every 10 minutes

## Requirements

- macOS 12.0 or later
- Xcode 13.0 or later

## Installation

1. Clone the repository

bash
git clone https://github.com/yourusername/crypto-gas-widget.git


2. Create a `Config.swift` file in the `GasPriceWidgetShared` folder with your API keys:

swift
struct Config {
static let etherscanApiKey = "YOUR_ETHERSCAN_API_KEY"
}


3. Open the project in Xcode
4. Build and run

## API Keys

This widget uses the following APIs:
- [Etherscan](https://etherscan.io/apis) - For Ethereum gas prices
- [Mempool.space](https://mempool.space/docs/api) - For Bitcoin fees
- [CoinGecko](https://www.coingecko.com/api/documentation) - For Solana prices

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)