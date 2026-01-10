// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {ERC20} from "erc20/ERC20.sol";
import {Clones} from "clones/Clones.sol";
import {ReentrancyGuardTransient} from "reentrancy/ReentrancyGuardTransient.sol";

contract Solid is ISolid, ERC20, ReentrancyGuardTransient {
    ISolid public immutable NOTHING = this;
    uint256 public immutable SUPPLY;

    constructor(uint256 supply) ERC20("", "NOTHING") {
        SUPPLY = supply;
    }

    function pool() public view returns (uint256 S, uint256 E) {
        if (this == NOTHING) revert Nothing();
        S = balanceOf(address(this));
        E = address(this).balance + 1 ether;
    }

    function buys(uint256 e) public view returns (uint256 s) {
        (uint256 S, uint256 E) = pool();
        s = S - S * E / (E + e);
    }

    function buy() public payable returns (uint256 s) {
        uint256 e = msg.value;
        (uint256 S, uint256 E) = pool();
        E -= e;
        s = S - S * E / (E + e);
        _update(address(this), msg.sender, s);
        emit Buy(this, e, s);
    }

    function sells(uint256 s) public view returns (uint256 e) {
        (uint256 S, uint256 E) = pool();
        e = E - E * S / (S + s);
        if (e > E - 1 ether) {
            e--;
        }
    }

    function sell(uint256 s) external nonReentrant returns (uint256 e) {
        e = sells(s);
        _update(msg.sender, address(this), s);
        emit Sell(this, s, e);
        (bool ok, bytes memory returned) = msg.sender.call{value: e}("");
        if (!ok) {
            if (returned.length > 0) {
                assembly {
                    revert(add(returned, 32), mload(returned))
                }
            } else {
                revert SellFailed();
            }
        }
    }

    function sellsFor(ISolid that, uint256 s) public view returns (uint256 thats) {
        uint256 e = sells(s);
        thats = that.buys(e);
    }

    function sellFor(ISolid that, uint256 s) external nonReentrant returns (uint256 thats) {
        uint256 e = sells(s);
        _update(msg.sender, address(this), s);
        emit Sell(this, s, e);
        thats = that.buy{value: e}();
        that.transfer(msg.sender, thats);
    }

    receive() external payable {
        if (this == NOTHING) revert Nothing();
    }

    function made(string calldata name, string calldata symbol)
        public
        view
        returns (bool yes, address home, bytes32 salt)
    {
        if (bytes(name).length == 0 || bytes(symbol).length == 0) {
            revert Nothing();
        }
        salt = keccak256(abi.encode(name, symbol));
        home = Clones.predictDeterministicAddress(address(NOTHING), salt, address(NOTHING));
        yes = home.code.length > 0;
    }

    function make(string calldata name, string calldata symbol) external returns (ISolid solid) {
        if (this != NOTHING) {
            solid = NOTHING.make(name, symbol);
        } else {
            (bool yes, address home, bytes32 salt) = made(name, symbol);
            solid = ISolid(payable(home));
            if (!yes) {
                home = Clones.cloneDeterministic(address(NOTHING), salt, 0);
                Solid(payable(home)).zzz_(name, symbol);
                emit Make(solid, name, symbol);
            }
        }
    }

    function zzz_(string calldata name, string calldata symbol) external {
        if (bytes(_symbol).length == 0) {
            _name = name;
            _symbol = symbol;
            _mint(address(this), SUPPLY);
        }
    }
}
