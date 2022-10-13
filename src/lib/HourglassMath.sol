// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Exp64x64} from "./Exp64x64.sol";
import {Math64x64} from "./Math64x64.sol";

error ZeroValue();

/// @dev Math library for Hourglass logic
/// @author https://github.com/kadenzipfel
library HourglassMath {
    using Math64x64 for int128;
    using Math64x64 for uint128;
    using Math64x64 for int256;
    using Math64x64 for uint256;
    using Exp64x64 for uint128;
    using Exp64x64 for int128;

    /// @notice Calculates token X reserves given token Y reserves
    /// @param tokenYReserves reserves of token Y
    /// @param liquidity amount of liquidity in pool
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tokenXReserves reserves for token X
    function tokenXReservesAtTokenYReserves(
        uint256 tokenYReserves,
        uint256 liquidity,
        uint256 timeRemaining,
        uint256 marketSpan
    ) public pure returns (uint128) {
        if (tokenYReserves == 0 || liquidity == 0) revert ZeroValue();

        // 1 - 1/√tₘ
        uint128 z = _calculateZ(_calculateTm(timeRemaining, marketSpan));

        // (1 - 1/√tₘ)√(2L^(1 - 1/√tₘ)-y^(1 - 1/√tₘ))
        return pow(
            sub(pow(fromInt(int256(mul(int128(2), int128(liquidity)))), z), pow(fromUInt(tokenYReserves), z)),
            div(int128(1), z)
        );
    }

    /// @dev Calculate time to maturity fraction (tₘ)
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tm fraction of time remaining in market open
    function _calculateTm(uint256 timeRemaining, uint256 marketSpan) private pure returns (uint128) {
        return uint128(div(timeRemaining.fromUInt(), marketSpan.fromUInt()));
    }

    /// @dev Calculate shared exponent z (1 - 1/√tₘ)
    /// @param tm fraction of time remaining in the market open
    /// @return z shared exponent of invariant
    function _calculateZ(uint128 tm) private pure returns (uint128) {
        return uint128(sub(int128(1), div(int128(1), sqrt(int128(tm)))));
    }
}
