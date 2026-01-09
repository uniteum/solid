// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Clones} from "clones/Clones.sol";

contract SolidSeller {
    SolidSeller public immutable PROTO = this;
    ISolid public thiss;
    ISolid public that;

    function thisName() public view returns (string memory) {
        return thiss.name();
    }

    function thisSymbol() public view returns (string memory) {
        return thiss.symbol();
    }

    function thatName() public view returns (string memory) {
        return that.name();
    }

    function thatSymbol() public view returns (string memory) {
        return that.symbol();
    }

    function sells(uint256 mine) external view returns (uint256 thats) {
        uint256 eth = thiss.sells(mine);
        thats = that.buys(eth);
    }

    function sell(uint256 mine) external returns (uint256 thats) {
        thiss.transferFrom(msg.sender, address(this), mine);
        uint256 eth = thiss.sell(mine);
        thats = that.buy{value: eth}();
        that.transfer(msg.sender, thats);
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
            seller = SolidSeller(payable(home));
            if (!yes) {
                home = Clones.cloneDeterministic(address(PROTO), salt, 0);
                SolidSeller(payable(home)).zzz_(my_, that_);
                emit Make(seller, my_, that_);
            }
        }
    }

    function zzz_(ISolid my_, ISolid that_) external {
        if (address(thiss) == address(0)) {
            thiss = my_;
            that = that_;
        }
    }

    constructor() {
        thiss = ISolid(address(0xdead));
    }

    receive() external payable {}

    event Make(SolidSeller indexed seller, ISolid indexed thiss, ISolid indexed that);
}
