// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ISupportsSelector {
    function supportsSelector(bytes4 selector) external view returns (bool);
}
