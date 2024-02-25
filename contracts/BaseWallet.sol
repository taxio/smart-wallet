// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";

import "./ISupportsSelector.sol";

contract BaseWallet is ERC1967Upgrade {
    using ECDSA for bytes32;
    using Address for address;

    struct BaseWalletStorage {
        bool initialized;
        address _verifyImpl;
        mapping(bytes4 => address) _executionImpls;
        address _fallbackImpl;
    }

    // TODO: update slot
    bytes32 private constant _STORAGE_SLOT =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

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

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "BaseWallet: not admin");
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

    fallback() external payable {
        BaseWalletStorage storage $ = _getStorage();

        bytes4 selector = bytes4(msg.data[0:4]);

        // Verification
        if (ISupportsSelector($._verifyImpl).supportsSelector(selector)) {
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
