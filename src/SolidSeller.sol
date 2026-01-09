// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Clones} from "clones/Clones.sol";

contract SolidSeller {
    SolidSeller public immutable PROTO = this;
    ISolid public my;
    ISolid public that;

    function balance() public view returns (uint256) {
        return my.balanceOf(msg.sender);
    }

    function name() public view returns (string memory) {
        return my.name();
    }

    function symbol() public view returns (string memory) {
        return my.symbol();
    }

    function thatName() public view returns (string memory) {
        return that.name();
    }

    function thatSymbol() public view returns (string memory) {
        return that.symbol();
    }

    function sells(uint256 mine) external view returns (uint256 thats) {
        uint256 eth = my.sells(mine);
        thats = that.buys(eth);
    }

    function sell(uint256 mine) external returns (uint256 thats) {
        uint256 eth = my.sell(mine);
        thats = that.buy{value: eth}();
    }

    function made(ISolid my_, ISolid that_) public view returns (bool yes, address home, bytes32 salt) {
        salt = keccak256(abi.encode(my_, that_));
        home = Clones.predictDeterministicAddress(address(PROTO), salt, address(PROTO));
        yes = home.code.length > 0;
    }

    function make(ISolid my_, ISolid that_) external returns (SolidSeller seller) {
        if (this != PROTO) {
            seller = PROTO.make(my_, that_);
        } else {
            (bool yes, address home, bytes32 salt) = made(my_, that_);
            seller = SolidSeller(home);
            if (!yes) {
                home = Clones.cloneDeterministic(address(PROTO), salt, 0);
                SolidSeller(home).zzz_(my_, that_);
                emit Make(seller, my_, that_);
            }
        }
    }

    function zzz_(ISolid my_, ISolid that_) external {
        if (address(my) == address(0)) {
            my = my_;
            that = that_;
        }
    }

    constructor() {
        my = ISolid(address(0xdead));
    }

    event Make(SolidSeller indexed seller, ISolid indexed my, ISolid indexed that);
}
