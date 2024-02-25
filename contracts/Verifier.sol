// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/UserOperation.sol";

import "./ISupportsSelector.sol";

contract Verifier is
    ERC1967Upgrade,
    BaseAccount,
    IERC165,
    IERC1271,
    ISupportsSelector
{
    using ECDSA for bytes32;
    using Address for address;

    struct VerifierStorage {
        bool initialized;
        address _entryPoint;
    }

    // TODO: update slot
    bytes32 private constant _STORAGE_SLOT =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getStorage() private pure returns (VerifierStorage storage $) {
        assembly {
            $.slot := _STORAGE_SLOT
        }
    }

    modifier initializer() {
        VerifierStorage storage $ = _getStorage();
        require(!$.initialized, "Verifier: already initialized");
        _;
        $.initialized = true;
    }

    function initialize(address _entryPoint) external initializer {
        VerifierStorage storage $ = _getStorage();
        require(_entryPoint.isContract(), "Verifier: entry point not contract");
        $._entryPoint = _entryPoint;
    }

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
        return IEntryPoint(_getStorage()._entryPoint);
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
