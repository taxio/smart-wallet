// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is Ownable, ERC721 {
  constructor() ERC721("TestERC721", "TEST") {}

  function mint(address _to, uint256 _tokenId) external onlyOwner {
    _mint(_to, _tokenId);
  }
}
