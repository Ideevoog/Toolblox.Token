// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IUniswapV3Factory
 * @notice Interface for the Uniswap V3 factory
 * @dev Handles the creation and management of Uniswap V3 pools
 */
interface IUniswapV3Factory {
    /**
     * @notice Initializes a pool with the given price
     * @param sqrtPriceX96 The initial sqrt price of the pool as a Q64.96
     */
    function initialize(uint160 sqrtPriceX96) external;
    
    /**
     * @notice Creates a pool for the given two tokens and fee
     * @param tokenA One of the two tokens in the desired pool
     * @param tokenB The other of the two tokens in the desired pool
     * @param fee The desired fee for the pool
     * @return pool The address of the newly created pool
     */
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /**
     * @notice Returns the tick spacing for a given fee amount
     * @dev Tick spacing is a global mapping on the factory contract that cannot be adjusted per pool
     * @param fee The fee amount to get the tick spacing for
     * @return The tick spacing for the given fee amount
     */
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);
} 