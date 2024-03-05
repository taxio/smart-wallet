// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

abstract contract WalletMixin is ERC1967Upgrade {
    // keccak256("mywallet.entryPoint")
    bytes32 internal constant _ENTRY_POINT_SLOT =
        0xb0d3409e8eb2b1bd1458a74523b1a19e7e4bb71a0a6134b2519f988dc6c11914;

    function _getEntryPoint() internal view returns (address entryPoint) {
        return StorageSlot.getAddressSlot(_ENTRY_POINT_SLOT).value;
    }

    function _setEntryPoint(address entryPoint) internal {
        StorageSlot.getAddressSlot(_ENTRY_POINT_SLOT).value = entryPoint;
    }
}
