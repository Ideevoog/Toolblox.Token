// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
	The implementation every proxy is created on, so that a proxy's creation code, and with it the
	proxy's address, doesn't depend on the code it will run.

	It has no functions: a call to a proxy still on the placeholder reverts. The deployer upgrades
	each proxy to its real code in the same transaction that creates it.
 **/
contract ProxyPlaceholder {}
