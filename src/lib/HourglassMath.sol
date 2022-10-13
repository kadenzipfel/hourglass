// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Math64x64 } from "./Math64x64.sol";

error ZeroValue();

/// @dev Math library for Hourglass logic
/// @author https://github.com/kadenzipfel
library HourglassMath {
    using Math64x64 for int128;
    using Math64x64 for uint128;
    using Math64x64 for int256;
    using Math64x64 for uint256;

    /// @dev Calculate time to maturity fraction (tₘ)
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tm fraction of time remaining in market open
    function _calculateTm(uint256 timeRemaining, uint256 marketSpan) private pure returns (uint128) {
        return uint128(div(timeRemaining.fromUInt(), marketSpan.fromUInt()));
    }
}
