// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IPluginExecutor {
    /// @notice Execute a call from a plugin through the account.
    /// @dev Permissions must be granted to the calling plugin for the call to go through.
    /// @param data The calldata to send to the account.
    /// @return The return data from the call.
    function executeFromPlugin(
        bytes calldata data
    ) external payable returns (bytes memory);

    /// @notice Execute a call from a plugin to a non-plugin address.
    /// @dev If the target is a plugin, the call SHOULD revert. Permissions must be granted to the calling plugin
    /// for the call to go through.
    /// @param target The address to be called.
    /// @param value The value to send with the call.
    /// @param data The calldata to send to the target.
    /// @return The return data from the call.
    function executeFromPluginExternal(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}
