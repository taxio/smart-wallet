// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../IPlugin.sol";

contract ValueLimitPlugin is IPlugin {
    struct Limitation {
        address owner;
        uint256 limit;
    }

    mapping(address owner => uint256 limit) _limits;

    function onInstall(bytes calldata data) external {
        uint256 limit = abi.decode(data, (uint256));
        _limits[msg.sender] = limit;
    }

    function onUninstall(bytes calldata) external {
        delete _limits[msg.sender];
    }

    function preExecutionHook(
        address, // caller
        address, // target
        uint256 value, // sendValue
        bytes calldata // sendData
    ) external view returns (bytes memory) {
        require(value <= _limits[msg.sender], "Value transfer exceeds limit");
        return "";
    }

    function postExecutionHook(bytes calldata preExecHookData) external {}
}
