// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract WalletProxy is ERC1967Proxy {
    constructor(
        address owner,
        address implementation,
        bytes memory data
    ) ERC1967Proxy(implementation, data) {
        _changeAdmin(owner);
    }
}
