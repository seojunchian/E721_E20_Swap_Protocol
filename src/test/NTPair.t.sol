// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {NTPair} from "../contracts/NTPair.sol";

contract NTPairTest is Test, NTPair {
    NTPair public ntPair;

    function setUp() public {
        ntPair = new NTPair();
    }

    function test_RetrieveERC721Token_IsNFTOwner(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) public returns (bool) {
        ntPair.retrieveERC721Token(_ERC721ContractAddress, _ERC721TokenId);
        address _ERC20ContractAddress = returnERC20Token(
            _ERC721ContractAddress,
            _ERC721TokenId
        );
        address pairAddress = ntPair.returnPairAddress(
            _ERC721ContractAddress,
            _ERC20ContractAddress,
            _ERC721TokenId
        );
        Pair memory pairInfo = PairAddress_To_PairInfo[pairAddress];
        return pairInfo.ERC721TokenOwner == msg.sender;
    }
}
