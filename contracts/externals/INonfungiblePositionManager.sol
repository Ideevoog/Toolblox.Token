// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title INonfungiblePositionManager
 * @notice Interface for the Uniswap V3 position manager
 * @dev Manages liquidity positions represented as NFTs in Uniswap V3
 */
interface INonfungiblePositionManager {
    /**
     * @notice Parameters for the mint function
     * @param token0 Address of the first token in the pair
     * @param token1 Address of the second token in the pair
     * @param fee Fee tier of the pool
     * @param tickLower Lower tick of the position
     * @param tickUpper Upper tick of the position
     * @param amount0Desired Desired amount of token0 to deposit
     * @param amount1Desired Desired amount of token1 to deposit
     * @param amount0Min Minimum amount of token0 to deposit
     * @param amount1Min Minimum amount of token1 to deposit
     * @param recipient Address that will receive the NFT
     * @param deadline Timestamp after which the transaction will revert
     */
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /**
     * @notice Parameters for the collect function
     * @param tokenId The ID of the NFT
     * @param recipient The address where collected tokens will be sent
     * @param amount0Max The maximum amount of token0 to collect
     * @param amount1Max The maximum amount of token1 to collect
     */
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /**
     * @notice Creates a new position wrapped in a NFT
     * @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
     * a method does not exist, i.e. the pool is assumed to be initialized.
     * @param params The params necessary to mint a position
     * @return tokenId The ID of the token that represents the minted position
     * @return liquidity The amount of liquidity for this position
     * @return amount0 The amount of token0 used to mint the position
     * @return amount1 The amount of token1 used to mint the position
     */
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice Collects tokens owed to a position
     * @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
     * @param params The params necessary to collect tokens owed
     * @return amount0 The amount of token0 collected
     * @return amount1 The amount of token1 collected
     */
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Transfers the NFT to a recipient
     * @dev The caller must be approved to transfer the NFT or be the owner
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param tokenId The ID of the NFT to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
} 