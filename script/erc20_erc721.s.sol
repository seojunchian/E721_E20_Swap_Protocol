// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {NTPair} from "../src/contracts/NTPair.sol";

contract ERC20_ERC721Script is Script {
    NTPair public ntPair;

    function setUp() public {
        ntPair = new NTPair();
    }

    function run() public {
        vm.broadcast();
    }
}
