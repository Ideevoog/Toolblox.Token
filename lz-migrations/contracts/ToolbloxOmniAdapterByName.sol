// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal interface for LayerZero Read configuration
// This is just for the migration scripts to interact with deployed contracts

interface TixReadAdapter {
    function READ_CHANNEL() external view returns (uint32);
    function peers(uint32 eid) external view returns (bytes32);
    function setReadChannel(uint32 channelId, bool active) external;
}

interface ILayerZeroEndpointV2 {
    function getSendLibrary(address sender, uint32 dstEid) external view returns (address lib);
    function getReceiveLibrary(address receiver, uint32 srcEid) external view returns (address lib);
    function setSendLibrary(address sender, uint32 dstEid, address lib) external;
    function setReceiveLibrary(address receiver, uint32 srcEid, address lib) external;
}

