// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./Proxy.sol";

contract ProxyFactory {
    event ProxyDeployed(
        address proxy,
        address implementation,
        address owner,
        bytes32 salt
    );

    constructor() {}

    function deploy(
        address implementation,
        address owner,
        bytes32 salt
    ) external returns (address) {
        address proxy = address(new Proxy{salt: salt}(owner, implementation));
        emit ProxyDeployed(proxy, implementation, owner, salt);
        return proxy;
    }

    function getAddress(
        address implementation,
        address owner,
        bytes32 salt
    ) external view returns (address) {
        return
            Create2.computeAddress(
                salt,
                keccak256(
                    abi.encodePacked(
                        type(Proxy).creationCode,
                        uint256(uint160(owner)),
                        uint256(uint160(implementation))
                    )
                )
            );
    }
}
