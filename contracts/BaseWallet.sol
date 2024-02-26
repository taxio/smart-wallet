// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";

import "./ISupportsSelector.sol";
import "./WalletMixin.sol";

contract BaseWallet is WalletMixin {
    using ECDSA for bytes32;
    using Address for address;

    struct BaseWalletStorage {
        bool initialized;
        address _verifyImpl;
        mapping(bytes4 => address) _executionImpls;
        address _fallbackImpl;
    }

    // keccak256("mywallet.base")
    bytes32 private constant _STORAGE_SLOT =
        0x2c4701970d09da25f7ed57ba2789825e251a0c930bb132616f4f10dfbd996367;

    function _getStorage() private pure returns (BaseWalletStorage storage $) {
        assembly {
            $.slot := _STORAGE_SLOT
        }
    }

    modifier initializer() {
        BaseWalletStorage storage $ = _getStorage();
        require(!$.initialized, "BaseWallet: already initialized");
        _;
        $.initialized = true;
    }

    modifier onlyOwner() {
        require(
            msg.sender == _getAdmin() || msg.sender == _getEntryPoint(),
            "BaseWallet: not owner"
        );
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "BaseWallet: not self");
        _;
    }

    function initialize(
        address verifyImpl,
        bytes calldata initVerifyImplData,
        address fallbackImpl,
        bytes calldata initFallbackImplData
    ) external initializer {
        BaseWalletStorage storage $ = _getStorage();

        // initialize verifier implementation
        if (initVerifyImplData.length > 0) {
            verifyImpl.functionDelegateCall(initVerifyImplData);
        }
        $._verifyImpl = verifyImpl;

        // initialize fallback implementation
        if (initFallbackImplData.length > 0) {
            fallbackImpl.functionDelegateCall(initFallbackImplData);
        }
        $._fallbackImpl = fallbackImpl;
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable onlyOwner returns (bytes memory) {
        // TODO: pre exec hook

        (bool success, bytes memory result) = target.call{value: value}(data);
        require(success, "BaseWallet: execution failed");

        // TODO: post exec hook

        return result;
    }

    fallback() external payable {
        BaseWalletStorage storage $ = _getStorage();

        bytes4 selector = bytes4(msg.data[0:4]);

        // Verification
        if (ISupportsSelector($._verifyImpl).supportsSelector(selector)) {
            // TODO: pre validation hook
            _delegate($._verifyImpl);
        }

        // Execution
        address execHandler = $._executionImpls[msg.sig];
        if (execHandler != address(0)) {
            _delegate(execHandler);
        }

        // Fallback
        require($._fallbackImpl != address(0), "BaseWallet: fallback not set");
        _delegate($._fallbackImpl);
    }

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
