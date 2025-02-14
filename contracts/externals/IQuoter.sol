// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Uniswap V3 Quoter interface
/// @notice Interface for getting swap quote estimates on Uniswap V3 (and PancakeSwap V3)
interface IQuoter {
    /**
     * @notice Returns the amount of `tokenOut` received for a given exact input swap
     * @dev Use `sqrtPriceLimitX96 = 0` if no price limit is required
     * @param tokenIn The token you are sending in
     * @param tokenOut The token you want to receive
     * @param fee The fee tier of the pool (e.g. 3000 for 0.3%)
     * @param amountIn The exact amount of `tokenIn` to swap
     * @param sqrtPriceLimitX96 The Q64.96 sqrt price limit
     * @return amountOut The amount of `tokenOut` received
     */
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /**
     * @notice Returns the amount of output token received for a multi-hop swap
     * @param path The path of the swap (tokenIn/tokenOut/fee tuples)
     * @param amountIn The exact amount of input token to swap
     * @return amountOut The amount of the output token received
     */
    function quoteExactInput(
        bytes calldata path,
        uint256 amountIn
    ) external returns (uint256 amountOut);

    /**
     * @notice Returns the amount of `tokenIn` required for a given exact output swap
     * @dev Use `sqrtPriceLimitX96 = 0` if no price limit is required
     * @param tokenIn The token you are sending in
     * @param tokenOut The token you want to receive
     * @param fee The fee tier of the pool (e.g. 3000 for 0.3%)
     * @param amountOut The exact amount of `tokenOut` you want to receive
     * @param sqrtPriceLimitX96 The Q64.96 sqrt price limit
     * @return amountIn The amount of `tokenIn` required
     */
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);

    /**
     * @notice Returns the amount of input token required for a multi-hop swap given an exact output
     * @param path The path of the swap (tokenOut/tokenIn/fee reversed for exact output)
     * @param amountOut The exact amount of output token desired
     * @return amountIn The amount of the input token required
     */
    function quoteExactOutput(
        bytes calldata path,
        uint256 amountOut
    ) external returns (uint256 amountIn);
}
