// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {ERC20} from "erc20/ERC20.sol";
import {Clones} from "clones/Clones.sol";
import {ReentrancyGuardTransient} from "reentrancy/ReentrancyGuardTransient.sol";

contract Solid is ISolid, ERC20, ReentrancyGuardTransient {
    uint256 constant AVOGADRO = 6.02214076e23;

    ISolid public immutable NOTHING = this;

    constructor() ERC20("", "NOTHING") {}

    function pool() public view returns (uint256 solPool, uint256 ethPool) {
        if (this == NOTHING) revert Nothing();
        solPool = balanceOf(address(this));
        ethPool = address(this).balance + 1 ether;
    }

    function buys(uint256 eth) public view returns (uint256 sol) {
        (uint256 solPool, uint256 ethPool) = pool();
        sol = solPool - solPool * (ethPool - eth) / ethPool;
    }

    function buy() public payable returns (uint256 sol) {
        uint256 eth = msg.value;
        sol = buys(eth);
        _update(address(this), msg.sender, sol);
        emit Buy(this, eth, sol);
    }

    function sells(uint256 sol) public view returns (uint256 eth) {
        (uint256 solPool, uint256 ethPool) = pool();
        eth = ethPool - ethPool * solPool / (solPool + sol);
        if (eth > ethPool - 1 ether) {
            eth = ethPool - 1 ether;
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

    function sellFor(ISolid that, uint256 sol) external nonReentrant returns (uint256 thats) {
        _update(msg.sender, address(this), sol);
        uint256 eth = sells(sol);
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
            _mint(address(this), AVOGADRO);
        }
    }
}
