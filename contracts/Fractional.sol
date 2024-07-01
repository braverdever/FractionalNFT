// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Shares.sol";

contract Fractional {
    struct NFT {
        address token;
        uint256 tokenID;
        address payable owner;
        uint256 price;
        Shares shares;
        uint256 sharesValue;
        uint256 sharesAmount;
        uint256 sharesLeft;
        bool isOpenForSale;
    }

    mapping(uint256 => NFT) public nftList;

    mapping(uint256 => uint256) public fund;

    uint256 public nftCounter;

    constructor() {}

    // lock NFT in fractional contract
    function lockNFT(
        address _token,
        uint256 _tokenID,
        uint256 _price,
        uint256 _sharesAmount
    ) external {
        // transfer NFT to contract
        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenID);

        // mint & transfer Shares to contract
        // set name of new token
        string memory tokenID = Strings.toString(_tokenID);
        string memory _tokenName = "FractionNFT";
        string memory tokenName = string(abi.encodePacked(_tokenName, tokenID));

        // set symbol of new token
        string memory _tokenSymbol = "FNFT";
        string memory tokenSymbol = string(
            abi.encodePacked(_tokenSymbol, tokenID)
        );

        // create new token
        Shares fToken = new Shares(tokenName, tokenSymbol, _sharesAmount);

        // // transfers tokens to this contract address
        // fToken.transfer(address(this), _sharesAmount);

        uint _sharesValue = _price / _sharesAmount;
        // update mapping
        nftList[nftCounter++] = NFT({
            token: _token,
            tokenID: _tokenID,
            owner: payable(msg.sender),
            price: _price,
            sharesValue: _sharesValue,
            sharesAmount: _sharesAmount,
            shares: fToken,
            sharesLeft: _sharesAmount,
            isOpenForSale: true
        });
    }
    // function for user to buy shares of NFT and hold Shares as validation token of the purchase
    function buyFractionalShares(
        uint256 _tokenID,
        uint256 _totalShares
    ) external payable {
        require(nftList[_tokenID].token != address(0), "Invalid NFT");
        require(nftList[_tokenID].isOpenForSale == true, "Not open for sale");
        require(
            msg.value >= nftList[_tokenID].sharesValue * _totalShares,
            "Insufficient funds"
        );

        require(
            nftList[_tokenID].sharesLeft >= _totalShares,
            "Insufficient shares"
        );

        nftList[_tokenID].shares.transferFrom(
            address(this),
            msg.sender,
            _totalShares
        );

        fund[_tokenID] += msg.value;

        nftList[_tokenID].sharesLeft -= _totalShares;

        (bool result, ) = nftList[_tokenID].owner.call{value: msg.value}("");
        require(result, "Transfer failed");
    }
    function returnFractionalShares(
        uint256 _tokenID,
        uint256 _totalShares
    ) external {
        require(nftList[_tokenID].token != address(0), "Invalid NFT");
        require(nftList[_tokenID].isOpenForSale == true, "Not open for sale");
        uint256 _totalValue = nftList[_tokenID].sharesValue * _totalShares;
        require(fund[_tokenID] >= _totalValue, "Insufficient funds");
        require(
            nftList[_tokenID].sharesLeft + _totalShares <=
                nftList[_tokenID].sharesAmount,
            "Invalid shares number"
        );

        nftList[_tokenID].shares.transferFrom(
            address(this),
            msg.sender,
            _totalShares
        );

        fund[_tokenID] -= _totalValue;

        nftList[_tokenID].sharesLeft += _totalShares;

        (bool result, ) = msg.sender.call{value: _totalValue}("");
        require(result, "Transfer failed");
    }
    function unlockNFT(uint256 _tokenID) external {
        require(
            msg.sender == nftList[_tokenID].owner,
            "Must be an owner to unlock the NFT"
        );
        IERC721(nftList[_tokenID].token).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenID
        );
        delete nftList[_tokenID];
    }

    function getNFTInfo(uint256 _tokenID) external view returns (NFT memory) {
        return nftList[_tokenID];
    }
}
