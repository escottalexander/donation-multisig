// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20("MockToken", "MOCK") {
    constructor() {
        _mint(msg.sender, 10000000000000000000000000000);
    }
}