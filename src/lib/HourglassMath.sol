// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Exp64x64} from "./Exp64x64.sol";
import {Math64x64} from "./Math64x64.sol";

error ZeroValue();
error InvalidTime();

/// @dev Math library for Hourglass logic
/// @author https://github.com/kadenzipfel
library HourglassMath {
    using Math64x64 for int128;
    using Math64x64 for uint128;
    using Math64x64 for int256;
    using Math64x64 for uint256;
    using Exp64x64 for uint128;
    using Exp64x64 for int128;

    uint128 public constant ONE = 0x10000000000000000; //   In 64.64

    /// @notice Calculates token X reserves given token Y reserves
    /// @param tokenYReserves reserves of token Y
    /// @param liquidity amount of liquidity in pool
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tokenXReserves reserves for token X
    function tokenXReservesAtTokenYReserves(
        uint128 tokenYReserves,
        uint128 liquidity,
        int128 timeRemaining,
        int128 marketSpan
    ) public pure returns (uint128) {
        if (tokenYReserves == 0 || liquidity == 0) revert ZeroValue();
        if (timeRemaining >= marketSpan) revert InvalidTime();

        // 1 - 1/√tₘ
        uint128 z = _calculateZ(_calculateTm(timeRemaining, marketSpan));

        // 2L^(1 - 1/√tₘ)
        uint256 l = (int128(2*ONE)).mulu(uint256(liquidity.pow(z, ONE)));

        // y^(1 - 1/√tₘ)
        uint256 y = tokenYReserves.pow(z, ONE);

        // 2L^(1 - 1/√tₘ)-y^(1 - 1/√tₘ)
        uint256 ly = l - y;

        // (1 - 1/√tₘ)√(2L^(1 - 1/√tₘ)-y^(1 - 1/√tₘ))
        return uint128(ly).pow(uint128(int128(ONE).div(int128(z))), ONE);
    }

    /// @dev Calculate time to maturity fraction (tₘ)
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tm fraction of time remaining in market open
    function _calculateTm(int128 timeRemaining, int128 marketSpan) private pure returns (uint128) {
        return uint128(timeRemaining.fromInt().div(marketSpan.fromInt()));
    }

    /// @dev Calculate shared exponent z (1 - 1/√tₘ)
    /// @param tm fraction of time remaining in the market open
    /// @return z shared exponent of invariant
    function _calculateZ(uint128 tm) private pure returns (uint128) {
        return uint128(int128(ONE).sub(int128(ONE).div(int128(tm).sqrt())));
    }
}
