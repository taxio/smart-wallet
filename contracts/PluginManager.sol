// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ERC6900/IPluginManager.sol";

contract PluginManager is IPluginManager {
    function installPlugin(
        address plugin,
        bytes32 manifestHash,
        bytes calldata, // pluginInstallData
        FunctionReference[] calldata dependencies
    ) external override {
        emit PluginInstalled(plugin, manifestHash, dependencies);
    }

    function uninstallPlugin(
        address plugin,
        bytes calldata, // config
        bytes calldata // pluginUninstallData
    ) external override {
        emit PluginUninstalled(plugin, true);
    }

    function _doRuntimeValidationHooks() internal {}

    function _doUserOperationValidatinoHooks() internal {}

    function _doPreExecutionHooks() internal {}

    function _doPostExecutionHooks() internal {}
}
