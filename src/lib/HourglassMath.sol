// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Exp64x64} from "./Exp64x64.sol";
import {Math64x64} from "./Math64x64.sol";

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
    /// @param liquidity amount of collateral liquidity in pool
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tokenXReserves reserves for token X
    function tokenXReservesAtTokenYReserves(
        uint256 tokenYReserves,
        uint256 liquidity,
        uint128 timeRemaining,
        uint128 marketSpan
    ) public pure returns (uint128) {
        // 1 - 1/√tₘ
        int128 z = _calculateZ(_calculateTm(int128(timeRemaining), int128(marketSpan)));

        // 2L^(1 - 1/√tₘ)
        int128 l = int128(2 * ONE).mul(liquidity.divu(uint256(ONE)).pow(z));

        // y^(1 - 1/√tₘ)
        int128 y = tokenYReserves.divu(uint256(ONE)).pow(z);

        // 2L^(1 - 1/√tₘ)-y^(1 - 1/√tₘ)
        int128 ly = l.sub(y);

        // (1 - 1/√tₘ)√(2L^(1 - 1/√tₘ)-y^(1 - 1/√tₘ))
        return uint128(ly.pow(int128(ONE).div(int128(z))));
    }

    /// @notice Calculates amount of tokens returned given amount of collateral deposited
    /// @param collateralIn amount of collateral being deposited
    /// @param tokenXReserves reserves of token X
    /// @param tokenYReserves reserves of token Y
    /// @param liquidity amount of liquidity in pool
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tokenXOut amount of tokens out for collateralIn
    function tokensOutForCollateralIn(
        uint256 collateralIn,
        uint256 tokenXReserves,
        uint256 tokenYReserves,
        uint256 liquidity,
        uint128 timeRemaining,
        uint128 marketSpan
    ) public pure returns (uint256) {
        // Increase amounts by collateral in
        tokenXReserves += collateralIn;
        tokenYReserves += collateralIn;

        // Calculate minimum token X reserves
        uint256 minTokenXReserves = tokenXReservesAtTokenYReserves(tokenYReserves, liquidity, timeRemaining, marketSpan);

        // Return token X delta
        return tokenXReserves - minTokenXReserves;
    }

    /// @notice Calculates amount of tokens required to receive given amount of collateral
    /// @param collateralOut amount of collateral to receive
    /// @param tokenXReserves reserves of token X
    /// @param tokenYReserves reserves of token Y
    /// @param liquidity amount of liquidity in pool
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tokenXIn amount of tokens required to receive collateralOut
    function tokensInForCollateralOut(
        uint256 collateralOut,
        uint256 tokenXReserves,
        uint256 tokenYReserves,
        uint256 liquidity,
        uint128 timeRemaining,
        uint128 marketSpan
    ) public pure returns (uint256) {
        // Get ending token Y reserves
        tokenYReserves -= collateralOut;

        // Get ending token X reserves
        uint256 tokenXEndReserves = tokenXReservesAtTokenYReserves(tokenYReserves, liquidity, timeRemaining, marketSpan);

        // Get delta between starting token X reserves and reserves before collateral is removed
        return tokenXEndReserves + collateralOut - tokenXReserves;
    }

    /// @dev Calculate time to maturity fraction (tₘ)
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tm fraction of time remaining in market open in 64.64
    function _calculateTm(int128 timeRemaining, int128 marketSpan) private pure returns (uint128) {
        return uint128(timeRemaining.fromInt().div(marketSpan.fromInt()));
    }

    /// @dev Calculate shared exponent z (1 - 1/√tₘ)
    /// @param tm fraction of time remaining in the market open
    /// @return z shared exponent of invariant in 64.64
    function _calculateZ(uint128 tm) private pure returns (int128) {
        return int128(int128(ONE).sub(int128(ONE).div(int128(tm).sqrt())));
    }
}
