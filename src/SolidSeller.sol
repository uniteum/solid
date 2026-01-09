// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Clones} from "clones/Clones.sol";

contract SolidSeller {
    SolidSeller public immutable PROTO = this;
    ISolid public my;
    ISolid public your;

    constructor() {
        my = ISolid(address(0xdead));
    }

    function sell(uint256 mine) external returns (uint256 yours) {
        uint256 eth = my.sell(mine);
        yours = your.buy{value: eth}();
    }

    function made(ISolid my_, ISolid your_) public view returns (bool yes, address home, bytes32 salt) {
        salt = keccak256(abi.encode(my_, your_));
        home = Clones.predictDeterministicAddress(address(PROTO), salt, address(PROTO));
        yes = home.code.length > 0;
    }

    function make(ISolid my_, ISolid your_) external returns (SolidSeller seller) {
        if (this != PROTO) {
            seller = PROTO.make(my_, your_);
        } else {
            (bool yes, address home, bytes32 salt) = made(my_, your_);
            seller = SolidSeller(home);
            if (!yes) {
                home = Clones.cloneDeterministic(address(PROTO), salt, 0);
                SolidSeller(home).zzz_(my_, your_);
                emit Make(seller, my_, your_);
            }
        }
    }

    function zzz_(ISolid my_, ISolid your_) external {
        if (address(my) == address(0)) {
            my = my_;
            your = your_;
        }
    }

    event Make(SolidSeller indexed seller, ISolid indexed my, ISolid indexed your);
}
