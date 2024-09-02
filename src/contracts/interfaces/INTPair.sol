// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INTPair {
    event TokenReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );
    event TokenRetrieved(
        address to,
        address ERC721ContractAddress,
        uint256 ERC721TokenId
    );
    event PairCreated(
        address indexed ERC721ContractAddress,
        uint256 indexed ERC721TokenId,
        address indexed ERC20ContractAddress,
        uint256 ERC20TokenValue,
        address pair
    );
    event Swapped(
        address ERC721ContractAddress,
        address ERC20ContractAddress,
        address newERC721TokenOwner,
        address newERC20TokenOwner,
        uint256 ERC721TokenId,
        uint256 ERC20TokenAmount
    );
    event ERC20TokenPriceChanged(
        address ERC721ContractAddress,
        address ERC20ContractAddress,
        uint256 ERC721TokenId,
        uint256 oldERC20TokenPrice,
        uint256 newERC20TokenPrice
    );

    function retrieveERC721Token(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) external;
    function createPair(
        address _ERC721ContractAddress,
        address _ERC20ContractAddress,
        uint256 _ERC721TokenId,
        uint256 _ERC20TokenValue
    ) external;
    function swap(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) external;
}
