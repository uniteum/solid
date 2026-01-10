// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {User, TestToken, IERC20, console} from "./User.sol";
import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "../src/Solid.sol";
import {SafeERC20} from "erc20/SafeERC20.sol";
import {Strings} from "strings/Strings.sol";

contract SolidUser is User {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    Solid public immutable NOTHING;
    TestToken ignore;
    IERC20 ignore2;

    constructor(string memory name, Solid nothing) User(name) {
        NOTHING = nothing;
    }

    modifier logging(string memory method, ISolid S, uint256 s) {
        _logging(method, S, s);
        _;
        logBalances();
    }

    function _logging(string memory method, ISolid S, uint256 s) private view {
        console.log(string.concat(name, " ", method, " ", s.toString(), " ", S.name()));
    }

    function buy(ISolid S, uint256 e) public logging("buy", S, e) returns (uint256 s) {
        s = S.buy{value: e}();
        console.log("s:", s);
    }

    function sell(ISolid S, uint256 s) public logging("sell", S, s) returns (uint256 e) {
        e = S.sell(s);
        console.log("e:", e);
    }

    function liquidate(ISolid S) public returns (uint256 e, uint256 s) {
        s = S.balanceOf(address(this));
        e = sell(S, s);
        assertHasNo(S);
    }
}
