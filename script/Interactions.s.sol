// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @dev Forge scripting requires importing `Script` to access cheatcodes like
 *      `vm.startBroadcast()` and `console` allows logging output during script execution.
 *
 *      Scripts in Foundry are NOT deployed to the blockchain. They are run locally
 *      or via `forge script` to interact with already-deployed contracts.
 */
import {Script, console} from "forge-std/Script.sol";

/**
 * @dev DevOpsTools is a Foundry utility that reads deployment records saved
 *      by `forge script` (usually in the `broadcast/` folder). It lets us
 *      find the most recently deployed address of a contract by name and chain ID,
 *      so we don't need to hardcode addresses.
 */
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

/// @dev Import FundMe so we can call its functions (fund, withdraw) via its interface.
import {FundMe} from "../src/FundMe.sol";

// =============================================================================
//  FundFundMe — Script to fund the most recently deployed FundMe contract
// =============================================================================

/**
 * @title  FundFundMe
 * @notice A Forge script that sends ETH to the most recently deployed FundMe contract.
 * @dev    Inherits from `Script` to access Foundry cheatcodes (vm.*).
 *         Run with: `forge script script/Interactions.s.sol:FundFundMe --broadcast`
 */
contract FundFundMe is Script {
    /// @notice The fixed amount of ETH sent to FundMe each time this script runs.
    uint256 constant SEND_VALUE = 0.01 ether;

    /**
     * @notice Entry point for the Forge script. Automatically called by `forge script`.
     * @dev    Looks up the most recent FundMe deployment on the current chain,
     *         then calls `fundFundMe()` to send ETH to it.
     *
     *         NOTE: We do NOT wrap this in vm.startBroadcast/stopBroadcast here
     *         because `fundFundMe()` already manages its own broadcast internally.
     *         Nesting two startBroadcast() calls is a bug and will cause a revert.
     */
    function run() external {
        // Retrieve the address of the most recently deployed FundMe contract
        // on the current network (identified by block.chainid).
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);

        // Delegate funding to the helper function, which handles broadcasting.
        fundFundMe(mostRecentlyDeployed);
    }

    /**
     * @notice Sends SEND_VALUE ETH to the FundMe contract at the given address.
     * @dev    This function is public so it can also be called directly from test
     *         contracts (e.g., InteractionsTest) without going through `run()`.
     *
     *         `vm.startBroadcast()` tells Foundry to sign and broadcast all
     *         transactions made after this call using the deployer's private key.
     *         `vm.stopBroadcast()` ends that signing session.
     *
     *         `payable(mostRecentlyDeployed)` is required because FundMe is a
     *         contract that receives ETH — casting to `payable` is Solidity's
     *         way of marking an address as ETH-receiving.
     *
     * @param mostRecentlyDeployed The address of the FundMe contract to fund.
     */
    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();

        // Call fund() and attach SEND_VALUE ETH using the {value: ...} syntax.
        // This is how you send ETH along with a function call in Solidity.
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();

        vm.stopBroadcast();

        // Log a confirmation message to the console (visible in script output).
        console.log("Funded FundMe with %s", SEND_VALUE);
    }
}

// =============================================================================
//  WithdrawFundMe — Script to withdraw funds from the most recently deployed FundMe
// =============================================================================

/**
 * @title  WithdrawFundMe
 * @notice A Forge script that withdraws all ETH from the most recently deployed FundMe.
 * @dev    Only the owner of the FundMe contract can successfully call `withdraw()`.
 *         If called by a non-owner, the transaction will revert on-chain.
 *         Run with: `forge script script/Interactions.s.sol:WithdrawFundMe --broadcast`
 */
contract WithdrawFundMe is Script {
    /**
     * @notice Entry point for the Forge script. Automatically called by `forge script`.
     * @dev    Looks up the most recent FundMe deployment, then delegates to
     *         `withdrawFundMe()` which handles the broadcast internally.
     *
     *         Same pattern as FundFundMe.run() — we avoid wrapping in an outer
     *         broadcast because withdrawFundMe() already manages one.
     */
    function run() external {
        // Retrieve the most recently deployed FundMe contract address for this chain.
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);

        // Delegate to the helper function, which handles broadcasting.
        withdrawFundMe(mostRecentlyDeployed);
    }

    /**
     * @notice Calls withdraw() on the FundMe contract at the given address.
     * @dev    Public so it can be called directly from test contracts.
     *
     *         Security note: `withdraw()` inside FundMe is restricted to the owner
     *         via a modifier (e.g., `onlyOwner`). If the broadcaster is not the
     *         owner, this transaction will revert and no ETH will be moved.
     *
     * @param mostRecentlyDeployed The address of the FundMe contract to withdraw from.
     */
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();

        // Cast to payable and call withdraw(). The payable cast is needed because
        // FundMe is deployed as a payable contract.
        FundMe(payable(mostRecentlyDeployed)).withdraw();

        vm.stopBroadcast();

        console.log("Withdrew FundMe balance!");
    }
}

/* foundry.toml
# Grant read access to the broadcast folder so DevOpsTools can find
# the most recently deployed contract address on the current chain.
fs_permissions = [{ access = "read", path = "./broadcast" }]
*/