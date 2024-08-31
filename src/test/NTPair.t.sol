// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {NTPair} from "../contracts/NTPair.sol";

contract NTPairTest is Test, NTPair {
    NTPair public ntPair;

    function setUp() public {
        ntPair = new NTPair();
    }
}
