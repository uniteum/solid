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

    function buys(uint256 eth) public view returns (uint256 sol) {
        (uint256 S, uint256 E) = pool();
        sol = S - S * E / (E + eth);
    }

    function buy() public payable returns (uint256 sol) {
        uint256 eth = msg.value;
        (uint256 S, uint256 E) = pool();
        E -= eth;
        sol = S - S * E / (E + eth);
        _update(address(this), msg.sender, sol);
        emit Buy(this, eth, sol);
    }

    function sells(uint256 sol) public view returns (uint256 eth) {
        (uint256 S, uint256 E) = pool();
        eth = E - E * S / (S + sol);
        if (eth > E - 1 ether) {
            eth--;
        }
    }

    function sell(uint256 sol) external nonReentrant returns (uint256 eth) {
        eth = sells(sol);
        _update(msg.sender, address(this), sol);
        emit Sell(this, sol, eth);
        (bool ok, bytes memory returned) = msg.sender.call{value: eth}("");
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

    function sellsFor(ISolid that, uint256 sol) public view returns (uint256 thats) {
        uint256 eth = sells(sol);
        thats = that.buys(eth);
    }

    function sellFor(ISolid that, uint256 sol) external nonReentrant returns (uint256 thats) {
        uint256 eth = sells(sol);
        _update(msg.sender, address(this), sol);
        emit Sell(this, sol, eth);
        thats = that.buy{value: eth}();
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

    function make(string calldata name, string calldata symbol) external returns (ISolid sol) {
        if (this != NOTHING) {
            sol = NOTHING.make(name, symbol);
        } else {
            (bool yes, address home, bytes32 salt) = made(name, symbol);
            sol = ISolid(payable(home));
            if (!yes) {
                home = Clones.cloneDeterministic(address(NOTHING), salt, 0);
                Solid(payable(home)).zzz_(name, symbol);
                emit Make(sol, name, symbol);
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
