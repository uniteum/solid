// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Clones} from "clones/Clones.sol";

contract SolidSeller {
    SolidSeller public immutable PROTO = this;
    ISolid public th1s;
    ISolid public that;

    function thisName() public view returns (string memory) {
        return th1s.name();
    }

    function thisSymbol() public view returns (string memory) {
        return th1s.symbol();
    }

    function thatName() public view returns (string memory) {
        return that.name();
    }

    function thatSymbol() public view returns (string memory) {
        return that.symbol();
    }

    function sells(uint256 mine) external view returns (uint256 thats) {
        uint256 eth = th1s.sells(mine);
        thats = that.buys(eth);
    }

    function sell(uint256 mine) external returns (uint256 thats) {
        th1s.transferFrom(msg.sender, address(this), mine);
        uint256 eth = th1s.sell(mine);
        thats = that.buy{value: eth}();
        that.transfer(msg.sender, thats);
    }

    function made(ISolid this_, ISolid that_) public view returns (bool yes, address home, bytes32 salt) {
        salt = keccak256(abi.encode(this_, that_));
        home = Clones.predictDeterministicAddress(address(PROTO), salt, address(PROTO));
        yes = home.code.length > 0;
    }

    function make(ISolid this_, ISolid that_) external returns (SolidSeller seller) {
        if (this != PROTO) {
            seller = PROTO.make(this_, that_);
        } else {
            (bool yes, address home, bytes32 salt) = made(this_, that_);
            seller = SolidSeller(payable(home));
            if (!yes) {
                home = Clones.cloneDeterministic(address(PROTO), salt, 0);
                SolidSeller(payable(home)).zzz_(this_, that_);
                emit Make(seller, this_, that_);
            }
        }
    }

    function zzz_(ISolid this_, ISolid that_) external {
        if (address(th1s) == address(0)) {
            th1s = this_;
            that = that_;
        }
    }

    constructor() {
        th1s = ISolid(address(0xdead));
    }

    receive() external payable {}

    event Make(SolidSeller indexed seller, ISolid indexed th1s, ISolid indexed that);
}
