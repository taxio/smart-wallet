// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Proxy {
    struct AddressSlot {
        address value;
    }

    // keccak256("eip1967.proxy.admin")
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    // keccak256("eip1967.proxy.implementation")
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256("mywallet.entryPoint")
    bytes32 internal constant _ENTRY_POINT_SLOT =
        0xb0d3409e8eb2b1bd1458a74523b1a19e7e4bb71a0a6134b2519f988dc6c11914;

    constructor(
        address admin,
        address entryPoint,
        address implementation,
        bytes memory data
    ) {
        _getAddressSlot(_ADMIN_SLOT).value = admin;
        _getAddressSlot(_ENTRY_POINT_SLOT).value = entryPoint;
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation;
        if (data.length > 0) {
            (bool success, bytes memory returndata) = implementation
                .delegatecall(data);
            if (!success) {
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
                    /// @solidity memory-safe-assembly
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("Proxy: initialization failed");
                }
            }
        }
    }

    function _getAddressSlot(
        bytes32 slot
    ) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    function _implementation() internal view returns (address) {
        return _getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate(_implementation());
    }

    receive() external payable {
        _delegate(_implementation());
    }
}
