// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./BaseWallet.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract SmartWallet is BaseWallet, IERC1271 {
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function.");
    _;
  }

  using ECDSA for bytes32;
  using Address for address;

  event OwnershipUpdated(address indexed previousOwner, address indexed newOwner);
  event ImplementationUpdated(address indexed previousImplementation, address indexed newImplementation);
  event Received(address indexed sender, uint256 value);

  constructor() {
    owner = msg.sender;
  }

  function updateOwner(address _owner) external onlyOwner {
    emit OwnershipUpdated(owner, _owner);
    owner = _owner;
  }

  function updateImplementation(address _implementation) external onlyOwner {
    emit ImplementationUpdated(implementation, _implementation);
    implementation = _implementation;
  }

  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external onlyOwner returns (bytes memory) {
    (bool success, bytes memory result) = _to.call{value: _value}(_data);
    require(success, "Transaction failed");
    return result;
  }

  function isValidSignature(
    bytes32 _hash,
    bytes memory _signature
  ) public view returns (bytes4 magicValue) {
    address signer = _hash.recover(_signature);
    if (owner == signer) {
      return IERC1271.isValidSignature.selector;
    } else {
      return 0xffffffff;
    }
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}
