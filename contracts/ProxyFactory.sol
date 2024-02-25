// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./Proxy.sol";

contract ProxyFactory {
    constructor() {}

    function deploy(
        address owner,
        address implementation,
        bytes memory data,
        bytes32 salt
    ) external returns (address) {
        address proxy = address(
            new WalletProxy{salt: salt}(owner, implementation, data)
        );
        return proxy;
    }

    function getAddress(
        address owner,
        address implementation,
        bytes memory data,
        bytes32 salt
    ) external view returns (address) {
        return
            Create2.computeAddress(
                salt,
                keccak256(
                    abi.encodePacked(
                        type(WalletProxy).creationCode,
                        uint256(uint160(owner)),
                        uint256(uint160(implementation)),
                        data
                    )
                )
            );
    }
}
