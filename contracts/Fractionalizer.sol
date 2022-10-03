// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";



/// @title NFT Frationalize
/// @notice This contract would allow a user to deposit NFT and recieve ERC20 token representing this NFT. Now, this ERC20 token can be be exchanges because it is fractional and fungible
contract FractionalizedNFT is ERC20, Ownable, ERC20Permit, ERC721Holder {
    IERC721 public collection;
    uint256 public tokenId;
    bool public initialized = false;
    bool public forSale = false;
    uint256 public salePrice;
    bool public canRedeem = false;


    /**
     * =====================================================
     * -------- CUSTOM ERRORS ------------------------------
     * =====================================================
     */
    error ContractAlreadyInit();
    error ValueShouldNotBeZero();
    error TokenNotForSale();

    /// @dev initializing the ERC20 token with the provided name 
    constructor() ERC20("X-FRACTION", "XFT") ERC20Permit("X-FRACTION") {}

    /// @dev when the user calls the function, the nft is transfer out of the user balance to the contract and the token i minted to the user 
    /// @notice call the the function to begin fractionalization 
    function initialize(address _collection, uint256 _tokenId, uint256 _amount) external onlyOwner {
        if(initialized) {
            revert ContractAlreadyInit();
        }
        if(_amount == 0) {
            revert ValueShouldNotBeZero();
        }
        collection = IERC721(_collection);
        collection.safeTransferFrom(msg.sender, address(this), _tokenId);
        tokenId = _tokenId;
        initialized = true;
        _mint(msg.sender, _amount);
    }

    /// @notice this function when called would set the nft to be sellable 
    /// @dev this function would set salePrice and forSale 
    /// @param price: this is the price the NFT would be cost
    function putForSale(uint256 price) external onlyOwner {
        salePrice = price;
        forSale = true;
    }

    /// @notice this function would be called be the buuyer to purchase the nft 
    function purchase() external payable {
        require(forSale, "Not for sale");
        require(msg.value >= salePrice, "Not enough ether sent");
        collection.transferFrom(address(this), msg.sender, tokenId);
        forSale = false;
        canRedeem = true;
    }


    /// @notice this fuction would be called be the NFT share holder to with their share of the NFT when after the purchase have been made 
    /// @dev thhis function should burn the ERC20 and deposit the ether that is due to the NFT share holder 
    function redeem(uint256 _amount) external {
        require(canRedeem, "Redemption not available");
        uint256 totalEther = address(this).balance;
        uint256 toRedeem = _amount * totalEther / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(toRedeem);
    }
}