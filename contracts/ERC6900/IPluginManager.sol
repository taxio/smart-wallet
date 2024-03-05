// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// Treats the first 20 bytes as an address, and the last byte as a function identifier.
type FunctionReference is bytes21;

library FunctionReferenceLib {
    // Empty or unset function reference.
    FunctionReference internal constant _EMPTY_FUNCTION_REFERENCE =
        FunctionReference.wrap(bytes21(0));
    // Magic value for runtime validation functions that always allow access.
    FunctionReference internal constant _RUNTIME_VALIDATION_ALWAYS_ALLOW =
        FunctionReference.wrap(bytes21(uint168(1)));
    // Magic value for hooks that should always revert.
    FunctionReference internal constant _PRE_HOOK_ALWAYS_DENY =
        FunctionReference.wrap(bytes21(uint168(2)));

    function pack(
        address addr,
        uint8 functionId
    ) internal pure returns (FunctionReference) {
        return
            FunctionReference.wrap(
                bytes21(bytes20(addr)) | bytes21(uint168(functionId))
            );
    }

    function unpack(
        FunctionReference fr
    ) internal pure returns (address addr, uint8 functionId) {
        bytes21 underlying = FunctionReference.unwrap(fr);
        addr = address(bytes20(underlying));
        functionId = uint8(bytes1(underlying << 160));
    }

    function isEmpty(FunctionReference fr) internal pure returns (bool) {
        return FunctionReference.unwrap(fr) == bytes21(0);
    }

    function isEmptyOrMagicValue(
        FunctionReference fr
    ) internal pure returns (bool) {
        return FunctionReference.unwrap(fr) <= bytes21(uint168(2));
    }

    function eq(
        FunctionReference a,
        FunctionReference b
    ) internal pure returns (bool) {
        return FunctionReference.unwrap(a) == FunctionReference.unwrap(b);
    }

    function notEq(
        FunctionReference a,
        FunctionReference b
    ) internal pure returns (bool) {
        return FunctionReference.unwrap(a) != FunctionReference.unwrap(b);
    }
}

interface IPluginManager {
    event PluginInstalled(
        address indexed plugin,
        bytes32 manifestHash,
        FunctionReference[] dependencies
    );

    event PluginUninstalled(
        address indexed plugin,
        bool indexed onUninstallSucceeded
    );

    /// @notice Install a plugin to the modular account.
    /// @param plugin The plugin to install.
    /// @param manifestHash The hash of the plugin manifest.
    /// @param pluginInstallData Optional data to be decoded and used by the plugin to setup initial plugin data
    /// for the modular account.
    /// @param dependencies The dependencies of the plugin, as described in the manifest. Each FunctionReference
    /// MUST be composed of an installed plugin's address and a function ID of its validation function.
    function installPlugin(
        address plugin,
        bytes32 manifestHash,
        bytes calldata pluginInstallData,
        FunctionReference[] calldata dependencies
    ) external;

    /// @notice Uninstall a plugin from the modular account.
    /// @param plugin The plugin to uninstall.
    /// @param config An optional, implementation-specific field that accounts may use to ensure consistency
    /// guarantees.
    /// @param pluginUninstallData Optional data to be decoded and used by the plugin to clear plugin data for the
    /// modular account.
    function uninstallPlugin(
        address plugin,
        bytes calldata config,
        bytes calldata pluginUninstallData
    ) external;
}
