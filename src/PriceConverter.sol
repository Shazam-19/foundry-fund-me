// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import Chainlink price feed interface
// Used to fetch the ETH/USD price on-chain
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// All functions here are 'internal':
// - Can only be called inside this contract
//   or by contracts inheriting from it.

library PriceConverter {
    // Returns the latest ETH/USD price from Chainlink.
    // Return value uses 18 decimals for consistency.
    function getPrice() internal view returns (uint256) {
        // We want to contract another contract so what do we need?
        // Address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // ABI (provided through the imported interface)

        // Sepolia ETH / USD Address
        // Docs: https://docs.chain.link/data-feeds/price-feeds/addresses
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        // How can we avoid hardcoding network-specific addresses like the price feed
        // to keep our contracts flexible?

        // Since we don't need all these returned data below, we can just remove them and leave a ','
        // (uint80 roundID, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "chainlink price <= 0");
        /*
        Chainlink ETH/USD price feed returns 8 decimals.

        Example:
        2000.00000000 = 200000000000

        Multiply by 1e10 to convert from 8 decimals to 18 decimals.
        */

        // casting to 'uint256' is safe because Chainlink price feeds always return non-negative values
        // (int256 >= 0 under normal operation), and we explicitly check `price > 0` before casting
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint256(price) * 1e10;

        // Solidity does not support floating-point numbers, so decimal precision must be handled manually.
    }

    /*
    Converts an ETH amount into its USD value.

    Example:
        How much is 1 ETH?
        Answer: 2000_000000000000000
        (2000_000000000000000 * 1_000000000000000000) / 1e18;
        $2000 = 1 ETH
    */
    function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
        // Fetch ETH price in USD (18 decimals)
        uint256 ethPrice = getPrice();

        // 1000000000000000000 * 1000000000000000000 = 1000000000000000000000000000000000000
        // 1000000000000000000000000000000000000 / 18 = 1000000000000000000
        // Always multiply before dividing to reduce precision loss.
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUSD;
    }

    // Returns the version of the deployed Chainlink price feed contract.
    function getVersion() internal view returns (uint256) {
        // Create an interface instance pointing to the deployed
        // Chainlink ETH/USD price feed contract and return its version.
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }
}
