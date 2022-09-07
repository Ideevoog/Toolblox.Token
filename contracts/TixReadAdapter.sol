// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OApp}              from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppRead}          from "@layerzerolabs/oapp-evm/contracts/oapp/OAppRead.sol";
import {Origin}            from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3}  from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {AddressCast}       from "@layerzerolabs/lz-evm-protocol-v2/contracts/libs/AddressCast.sol";
import {EVMCallRequestV1, ReadCodecV1} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/ReadCodecV1.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

// ── Toolblox Tix service locator ──────────────────────────────────────────────
interface IServiceLocator {
    function getService(bytes32 name) external view returns (address);
}

contract TixReadAdapter is OAppRead, OAppOptionsType3 {
    using OptionsBuilder for bytes;
    // Resolve services for incoming PUSH on THIS chain
    IServiceLocator public immutable tix;

    // Read channel ID (wired via lz-migrations tooling)
    uint32 public READ_CHANNEL;
    uint16 public constant READ_TYPE = 1;

    // Simple pause controls
    bool public paused;
    mapping(uint32 => bool) public eidPaused;

    // ---- helpers -------------------------------------------------------------

    function _padded32(uint256 n) private pure returns (uint256) {
        // rounds up to next multiple of 32
        return (n + 31) / 32 * 32;
    }

    function _estimateRespSize(bytes calldata ctx, uint256 retGuess)
        private
        pure
        returns (uint256)
    {
        // tuple: (bytes ret, bytes ctx, bytes32 svcKey, address returnTo, bytes4 cbSel)
        // total = heads(5*32) + dyn(ret: 32 + pad(retGuess)) + dyn(ctx: 32 + pad(ctx.length))
        uint256 heads = 5 * 32;
        uint256 dynRet = 32 + _padded32(retGuess);
        uint256 dynCtx = 32 + _padded32(ctx.length);
        return heads + dynRet + dynCtx;
    }

    function _buildReadCmd(
        uint32  dstEid,
        bytes32 svcKey,
        bytes4  readSel,
        bytes   calldata readArgs,
        bytes   calldata ctx,
        address returnTo,
        bytes4  cbSel,
        address destAdapter // the trusted adapter on dst
    ) private view returns (bytes memory cmd) {
        EVMCallRequestV1[] memory reqs = new EVMCallRequestV1[](1);
        reqs[0] = EVMCallRequestV1({
            appRequestLabel: 1,
            targetEid:       dstEid,
            isBlockNum:      false,
            blockNumOrTimestamp: uint64(block.timestamp),
            confirmations:   15,
            to:              destAdapter, // call the DEST adapter’s proxy
            callData: abi.encodeWithSelector(
                this.proxyReadWithContext.selector,
                svcKey, readSel, readArgs, ctx, returnTo, cbSel
            )
        });
        cmd = ReadCodecV1.encode(0, reqs);
    }

    constructor(address endpoint, address tixOnThisChain)
        OAppRead(endpoint, msg.sender)
        Ownable(msg.sender)
    {
        tix = IServiceLocator(tixOnThisChain);
    }

    // ── Admin ─────────────────────────────────────────────────────────────────
    // Inherit onlyOwner from OZ Ownable via LayerZero's OApp hierarchy

    /// Wire/unwire the read channel (for lzRead, peer is yourself on that channel)
    function setReadChannel(uint32 channelId, bool active) public override onlyOwner {
        READ_CHANNEL = channelId;
        _setPeer(channelId, active ? AddressCast.toBytes32(address(this)) : bytes32(0));
    }

    function pause() external onlyOwner { paused = true; }
    function unpause() external onlyOwner { paused = false; }
    function pauseEid(uint32 eid, bool p) external onlyOwner { eidPaused[eid] = p; }

    /// Universal lzRead: builds options for the caller using heuristics.
    /// Pass only essentials; we compute callback gas & size.
    function lzReadByNameWithCtx(
        address refundTo,
        uint32  dstEid,
        bytes32 svcKey,
        bytes4  readSel,
        bytes   calldata readArgs,
        bytes4  cbSel,
        bytes   calldata ctx
    ) external payable returns (MessagingReceipt memory receipt) {
        require(msg.sender.code.length > 0, "TB:caller must be contract");
        require(refundTo != address(0), "TB:refundTo=0");

        bytes32 peerB = peers[dstEid];
        require(peerB != bytes32(0), "TB:no peer");
        address destAdapter = AddressCast.toAddress(peerB);

        // Heuristic choices
        uint256 callbackGas = 200_000;           // should fit a typical finish() path
        uint256 retGuess    = 96;                // e.g., two words (address+uint) or small tuple
        uint256 respSize    = _estimateRespSize(ctx, retGuess);

        // Cap response size to avoid overpaying (raise if you expect bigger blobs)
        if (respSize < 256) respSize = 256;
        if (respSize > 4096) respSize = 4096;

        bytes memory opts = OptionsBuilder.newOptions();
        opts = opts.addExecutorLzReadOption(uint128(callbackGas), uint32(respSize), uint128(0));

        bytes memory cmd = _buildReadCmd(
            dstEid, svcKey, readSel, readArgs, ctx, msg.sender, cbSel, destAdapter
        );

        // Use the IOAppOptionsType3 combineOptions via external self-call to handle calldata typing
        bytes memory finalOptions = this.combineOptions(READ_CHANNEL, READ_TYPE, opts);

        return _lzSend(
            READ_CHANNEL,
            cmd,
            finalOptions,
            MessagingFee(msg.value, 0),
            payable(refundTo)
        );
    }

    /// Same as above, but lets caller pass a pre-built options blob (for exact control).
    function lzReadByNameWithCtx(
        address refundTo,
        uint32  dstEid,
        bytes32 svcKey,
        bytes4  readSel,
        bytes   calldata readArgs,
        bytes4  cbSel,
        bytes   calldata ctx,
        bytes   calldata extraOpts
    ) external payable returns (MessagingReceipt memory receipt) {
        bytes32 peerB = peers[dstEid];
        require(peerB != bytes32(0), "TB:no peer");
        address destAdapter = AddressCast.toAddress(peerB);
        require(refundTo != address(0), "TB:refundTo=0");

        bytes memory cmd = _buildReadCmd(
            dstEid, svcKey, readSel, readArgs, ctx, msg.sender, cbSel, destAdapter
        );

        return _lzSend(
            READ_CHANNEL,
            cmd,
            combineOptions(READ_CHANNEL, READ_TYPE, extraOpts),
            MessagingFee(msg.value, 0),
            payable(refundTo)
        );
    }

    /// DEST view proxy executed by DVNs during lzRead:
    ///  1) staticcall readSel(readArgs)
    ///  2) return (ret, ctx, svcKey, returnTo, cbSel) — echoed back to SOURCE
    function proxyReadWithContext(
        bytes32 svcKey,
        bytes4  readSel,
        bytes   calldata readArgs,
        bytes   calldata ctx,
        address returnTo,
        bytes4  cbSel
    )
        external
        view
        returns (bytes memory ret, bytes memory ctxOut, bytes32 svcKeyOut, address returnToOut, bytes4 cbSelOut)
    {
        address target = tix.getService(svcKey);
        require(target != address(0) && target.code.length > 0, "TB:no service");

        (bool ok, bytes memory r) = target.staticcall(bytes.concat(readSel, readArgs));
        require(ok, "TB:read failed");

        return (r, ctx, svcKey, returnTo, cbSel);
    }

    function _lzReceive(
        Origin calldata origin,
        bytes32 /*guid*/,
        bytes calldata message,
        address /*executor*/,
        bytes calldata /*extraData*/
    ) internal override {
        require(!paused && !eidPaused[origin.srcEid], "TB:paused");

        // READ-origin hardening
        require(origin.srcEid == READ_CHANNEL, "TB:bad read channel");

        // peer for READ_CHANNEL must be ourselves (wired via setReadChannel)
        bytes32 targetPeer = peers[READ_CHANNEL];
        require(targetPeer != bytes32(0), "TB:read peer not set");
        address expected = AddressCast.toAddress(targetPeer);
        require(expected == address(this), "TB:read peer miscfg");
        require(AddressCast.toAddress(bytes32(origin.sender)) == expected, "TB:bad read peer");

        // Decode READ response: (ret, ctx, svcKey, returnTo, cbSel)
        (bytes memory ret, bytes memory ctx, bytes32 svcKey, address returnTo, bytes4 cbSel) =
            abi.decode(message, (bytes, bytes, bytes32, address, bytes4));

        // Only call contracts
        require(returnTo.code.length > 0, "TB:bad returnTo");

        (bool ok,) = returnTo.call(abi.encodeWithSelector(cbSel, ctx, svcKey, ret));
        require(ok, "TB:callback failed");
    }

}
