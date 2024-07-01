// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Shares is ERC20, Ownable {
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenAmount
    ) ERC20(tokenName, tokenSymbol) Ownable(msg.sender) {
        _mint(_msgSender(), tokenAmount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 1;
    }
}
