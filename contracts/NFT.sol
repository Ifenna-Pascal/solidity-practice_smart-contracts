//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    /// @dev auto increment
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;
    event makeToken( uint id );

    constructor (address marketplaceAddress) ERC721("IfeMoney", "IM") {
        contractAddress = marketplaceAddress;
    }

    /// @dev create a new token
    /// @param tokenURI : token URI
    function createToken ( string memory tokenURI ) public returns (uint) {
        
        // set a token id for the token to be minted
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        // minting new tokens
        _mint( msg.sender, newItemId );
        // generate token URI
        _setTokenURI(newItemId, tokenURI);
        // grant permission to marketplace
        setApprovalForAll(contractAddress, true);
        emit makeToken(newItemId);
        // returns tokenId
        return newItemId;
    }
}