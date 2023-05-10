// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Proxy {
  address implementation;
  address public owner;

  constructor(address _owner, address _implementation) {
    owner = _owner;
    implementation = _implementation;
  }

  fallback() external payable {
    _delegateCall(implementation);
  }

  receive() external payable {
    _delegateCall(implementation);
  }
  
  function _delegateCall(address impl) internal {
    assembly {
      calldatacopy(0, 0, calldatasize())
      let success := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      if eq(success, 0) {
          revert(0, returndatasize())
      }
      return(0, returndatasize())
    }
  }
}
