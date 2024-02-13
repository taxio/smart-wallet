// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";

contract SmartWallet is ERC1967Upgrade, IERC1271, BaseAccount, Initializable {
    using ECDSA for bytes32;
    using Address for address;

    modifier selfAuth() {
        require(msg.sender == address(this), "SmartWallet: not self-auth");
        _;
    }

    function initialize(address _entryPoint) external initializer {
        StorageSlot.getAddressSlot(_ENTRY_POINT_SLOT).value = _entryPoint;
    }

    bytes4 internal constant _VALID_SIGNATURE =
        bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    bytes32 internal constant _ENTRY_POINT_SLOT =
        keccak256("erc4337.entryPoint");

    function updateEntryPoint(address newEntryPoint) external selfAuth {
        StorageSlot.getAddressSlot(_ENTRY_POINT_SLOT).value = newEntryPoint;
    }

    function executeFromEntryPoint(
        address target,
        uint256 value,
        bytes calldata data
    ) external {
        _requireFromEntryPoint();
        _call(target, value, data);
    }

    function _call(
        address target,
        uint256 value,
        bytes calldata data
    ) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return IEntryPoint(StorageSlot.getAddressSlot(_ENTRY_POINT_SLOT).value);
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override returns (uint256 validationData) {
        if (
            isValidSignature(
                userOpHash.toEthSignedMessageHash(),
                userOp.signature
            ) != _VALID_SIGNATURE
        ) {
            return SIG_VALIDATION_FAILED;
        }
        return 0;
    }

    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) public view returns (bytes4) {
        if (_hash.recover(_signature) == _getAdmin()) {
            return _VALID_SIGNATURE;
        } else {
            return 0xffffffff;
        }
    }

    receive() external payable {}
}
