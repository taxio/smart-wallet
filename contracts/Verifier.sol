// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";

import "./ISupportsSelector.sol";
import "./WalletMixin.sol";

contract Verifier is
    WalletMixin,
    BaseAccount,
    IERC165,
    IERC1271,
    ISupportsSelector
{
    using ECDSA for bytes32;
    using Address for address;

    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC1271).interfaceId ||
            interfaceId == type(IAccount).interfaceId ||
            interfaceId == type(ISupportsSelector).interfaceId;
    }

    function supportsSelector(
        bytes4 selector
    ) external pure override returns (bool) {
        return
            selector == IERC1271.isValidSignature.selector ||
            selector == IAccount.validateUserOp.selector ||
            selector == BaseAccount.entryPoint.selector;
    }

    function isValidSignature(
        bytes32 msgHash,
        bytes calldata signature
    ) external view override returns (bytes4) {
        address signer = msgHash.recover(signature);
        if (signer == _getAdmin()) {
            return IERC1271.isValidSignature.selector;
        } else {
            return 0xffffffff;
        }
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return IEntryPoint(_getEntryPoint());
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override returns (uint256) {
        bytes32 msgHash = userOpHash.toEthSignedMessageHash();
        if (msgHash.recover(userOp.signature) != _getAdmin()) {
            return SIG_VALIDATION_FAILED;
        }
        return 0;
    }
}
