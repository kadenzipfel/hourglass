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
    /// @param liquidity amount of collateral liquidity in pool
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return tokenXReserves reserves for token X
    function tokenXReservesAtTokenYReserves(
        uint256 tokenYReserves,
        uint256 liquidity,
        int128 timeRemaining,
        int128 marketSpan
    ) public pure returns (uint128) {
        if (tokenYReserves == 0 || liquidity == 0) revert ZeroValue();
        if (timeRemaining >= marketSpan) revert InvalidTime();

        // 1 - 1/√tₘ
        int128 z = _calculateZ(_calculateTm(timeRemaining, marketSpan));

        // 2L^(1 - 1/√tₘ)
        int128 l = int128(2 * ONE).mul(liquidity.divu(uint256(ONE)).pow(z));

        // y^(1 - 1/√tₘ)
        int128 y = tokenYReserves.divu(uint256(ONE)).pow(z);

        // 2L^(1 - 1/√tₘ)-y^(1 - 1/√tₘ)
        int128 ly = l.sub(y);

        // (1 - 1/√tₘ)√(2L^(1 - 1/√tₘ)-y^(1 - 1/√tₘ))
        return uint128(ly.pow(int128(ONE).div(int128(z))));
    }

    /// @notice Calculates amount of collateral liquidity given reserves of token x and y
    /// @param tokenXReserves reserves of token X
    /// @param tokenYReserves reserves of token Y
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param tokenXReserves total market open time span (in seconds)
    /// @return liquidity amount of collateral liquidity at given token reserves
    function liquidityAtTokenReserves(
        uint256 tokenXReserves,
        uint256 tokenYReserves,
        int128 timeRemaining,
        int128 marketSpan
    ) public pure returns (uint128) {
        if (tokenXReserves == 0 || tokenYReserves == 0) revert ZeroValue();
        if (timeRemaining >= marketSpan) revert InvalidTime();

        // 1 - 1/√tₘ
        int128 z = _calculateZ(_calculateTm(timeRemaining, marketSpan));

        // x^(1 - 1/√tₘ)
        int128 x = tokenXReserves.divu(uint256(ONE)).pow(z);

        // y^(1 - 1/√tₘ)
        int128 y = tokenYReserves.divu(uint256(ONE)).pow(z);

        // x^(1 - 1/√tₘ) + y^(1 - 1/√tₘ)
        int128 xy = x.add(y);

        // 2^(-1/(1-1/√tₘ))
        int128 t = int128(2 * ONE).pow((-1 * int128(ONE)).div(int128(z)));

        // 2^(-1/(1-1/√tₘ))((1 - 1/√tₘ)√(x^(1 - 1/√tₘ) + y^(1 - 1/√tₘ)))
        return uint128(t.mul(xy.pow(int128(ONE).div(int128(z)))));
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
        int128 timeRemaining,
        int128 marketSpan
    ) public pure returns (uint256) {
        if (liquidity == 0) revert ZeroValue();

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
        int128 timeRemaining,
        int128 marketSpan
    ) public pure returns (uint256) {
        // Decrease amounts by collateral out
        tokenXReserves -= collateralOut;
        tokenYReserves -= collateralOut;

        // Calculate maximum token X reserves
        uint256 maxTokenXReserves = tokenXReservesAtTokenYReserves(tokenYReserves, liquidity, timeRemaining, marketSpan);

        // Return token X delta
        return tokenXReserves - maxTokenXReserves;
    }

    /// @notice Calculates the amount of collateral required for given amount of token X out
    /// @param tokenXOut amount of token
    /// @param tokenXReserves reserves of token X
    /// @param tokenYReserves reserves of token Y
    /// @param liquidity amount of liquidity in pool
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return collateralIn amount of collateral required for tokenXOut
    function collateralInForTokensOut(
        uint256 tokenXOut,
        uint256 tokenXReserves,
        uint256 tokenYReserves,
        uint256 liquidity,
        int128 timeRemaining,
        int128 marketSpan
    ) public pure returns (uint256) {
        // Decrease token X reserves by tokenXOut
        tokenXReserves -= tokenXOut;

        // Calculate liquidity with reduced token X reserves
        uint256 reducedLiquidity = liquidityAtTokenReserves(tokenXReserves, tokenYReserves, timeRemaining, marketSpan);

        // Return liquidity delta
        return liquidity - reducedLiquidity;
    }

    /// @notice Calculates the amount of collateral to receive for given amount of token X in
    /// @param tokenXIn amount of token
    /// @param tokenXReserves reserves of token X
    /// @param tokenYReserves reserves of token Y
    /// @param liquidity amount of liquidity in pool
    /// @param timeRemaining time remaining until market maturity (in seconds)
    /// @param marketSpan total market open time span (in seconds)
    /// @return collateralOut amount of collateral received for tokenXIn
    function collateralOutForTokensIn(
        uint256 tokenXIn,
        uint256 tokenXReserves,
        uint256 tokenYReserves,
        uint256 liquidity,
        int128 timeRemaining,
        int128 marketSpan
    ) public pure returns (uint256) {
        // Increase token X reserves by tokenXIn
        tokenXReserves += tokenXIn;

        // Calculate liquidity with increased token X reserves
        uint256 increasedLiquidity = liquidityAtTokenReserves(tokenXReserves, tokenYReserves, timeRemaining, marketSpan);

        // Return liquidity delta
        return increasedLiquidity - liquidity;
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
