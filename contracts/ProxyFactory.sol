// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./Proxy.sol";

contract ProxyFactory {
    event Deployed(address indexed proxy);

    constructor() {}

    function deploy(
        address admin,
        address entryPoint,
        address implementation,
        bytes memory data,
        bytes32 salt
    ) external returns (address) {
        address proxy = address(
            new Proxy{salt: salt}(admin, entryPoint, implementation, data)
        );

        emit Deployed(proxy);

        return proxy;
    }

    function getAddress(
        address admin,
        address entryPoint,
        address implementation,
        bytes memory data,
        bytes32 salt
    ) external view returns (address) {
        return
            Create2.computeAddress(
                salt,
                keccak256(
                    abi.encodePacked(
                        type(Proxy).creationCode,
                        uint256(uint160(admin)),
                        uint256(uint160(entryPoint)),
                        uint256(uint160(implementation)),
                        data
                    )
                )
            );
    }
}
