// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IPlugin.sol";

contract PluginManager {
    event PluginInstalled(address indexed plugin);
    event PluginUninstalled(address indexed plugin);

    struct PluginManagerStorage {
        address plugin;
    }

    // keccak256("mywallet.pluginManager")
    bytes32 private constant _PLUGIN_MANAGER_SLOT =
        0x2a16e8bde9b825607904164a4bad8d1a3b46445a5478908e8239bc9781423110;

    function _getPluginManagerStorage()
        private
        pure
        returns (PluginManagerStorage storage $)
    {
        assembly {
            $.slot := _PLUGIN_MANAGER_SLOT
        }
    }

    function installPlugin(
        address plugin,
        bytes calldata pluginInstallData
    ) external {
        PluginManagerStorage storage $ = _getPluginManagerStorage();

        require(
            $.plugin == address(0),
            "PluginManager: plugin already installed"
        );

        $.plugin = plugin;

        IPlugin(plugin).onInstall(pluginInstallData);
        emit PluginInstalled(plugin);
    }

    function uninstallPlugin(
        address plugin,
        bytes calldata, // config
        bytes calldata pluginUninstallData
    ) external {
        PluginManagerStorage storage $ = _getPluginManagerStorage();

        require(
            $.plugin == plugin,
            "PluginManager: the plugin is not installed"
        );

        $.plugin = address(0);

        IPlugin(plugin).onUninstall(pluginUninstallData);
        emit PluginUninstalled(plugin);
    }

    function _doRuntimeValidationHook(
        address sender,
        uint256 value,
        bytes calldata data
    ) internal {
        PluginManagerStorage storage $ = _getPluginManagerStorage();
        if ($.plugin != address(0)) {
            IPlugin($.plugin).preRuntimeValidationHook(sender, value, data);
        }
    }

    function _doUserOperationValidatinoHook(
        UserOperation memory userOp,
        bytes32 userOpHash
    ) internal {
        PluginManagerStorage storage $ = _getPluginManagerStorage();
        if ($.plugin != address(0)) {
            IPlugin($.plugin).preUserOpValidationHook(userOp, userOpHash);
        }
    }

    function _doPreExecutionHook(
        address sender,
        address target,
        uint256 value,
        bytes calldata data
    ) internal returns (bytes memory postHookData) {
        PluginManagerStorage storage $ = _getPluginManagerStorage();
        if ($.plugin == address(0)) {
            return postHookData;
        }

        postHookData = IPlugin($.plugin).preExecutionHook(
            sender,
            target,
            value,
            data
        );
    }

    function _doPostExecutionHook(bytes memory hookData) internal {
        PluginManagerStorage storage $ = _getPluginManagerStorage();
        if ($.plugin != address(0)) {
            IPlugin($.plugin).postExecutionHook(hookData);
        }
    }
}
