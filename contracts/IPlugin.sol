// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";

interface IPlugin {
    function onInstall(bytes calldata data) external;

    function onUninstall(bytes calldata data) external;

    function preUserOpValidationHook(
        UserOperation memory userOp,
        bytes32 userOpHash
    ) external returns (uint256);

    function preRuntimeValidationHook(
        address sender,
        uint256 value,
        bytes calldata data
    ) external;

    function preExecutionHook(
        address sender,
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);

    function postExecutionHook(bytes calldata preExecHookData) external;
}
