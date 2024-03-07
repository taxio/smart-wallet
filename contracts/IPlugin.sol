// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";

interface IPlugin {
    function onInstall(bytes calldata data) external;

    function onUninstall(bytes calldata data) external;

    function preExecutionHook(
        address caller,
        address target,
        uint256 sendValue,
        bytes calldata sendData
    ) external returns (bytes memory);

    function postExecutionHook(bytes calldata preExecHookData) external;
}
