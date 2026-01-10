// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {ERC20} from "erc20/ERC20.sol";
import {Clones} from "clones/Clones.sol";
import {ReentrancyGuardTransient} from "reentrancy/ReentrancyGuardTransient.sol";
import {ExponentialCurve} from "./ExponentialCurve.sol";

contract Solid is ISolid, ERC20, ReentrancyGuardTransient {
    // Scale factor: work in whole tokens (divide by 1e18) to avoid precision loss
    uint256 constant SCALE = 1e18;

    // Exponential curve parameters: p(s) = P0 * r^s
    uint256 constant P0 = 1e15; // Initial price: 1e15 wei per token (~$0.003 at ETH=$3k)
    uint256 constant NUM = 100001; // Growth rate numerator
    uint256 constant DEN = 100000; // Growth rate denominator (r = 1.00001 = 0.001% per token)

    ISolid public immutable NOTHING = this;

    constructor() ERC20("", "NOTHING") {}

    /**
     * @notice Core bonding curve: calculate cost in ETH to buy dx tokens at supply s (scaled)
     * @param eth ETH amount in wei
     * @param s Current supply in scaled units (whole tokens)
     * @return dx Number of tokens that can be bought (scaled)
     */
    function _ethToSol(uint256 eth, uint256 s) internal pure returns (uint256 dx) {
        // Convert r = NUM/DEN to WAD
        uint256 rWad = ExponentialCurve.toWad(NUM, DEN);

        // Binary search to find dx such that cost(s, dx) ≈ eth
        uint256 low = 0;
        uint256 high = eth / P0 + 1000; // Upper bound estimate

        while (low < high) {
            uint256 mid = (low + high + 1) / 2;
            uint256 c = ExponentialCurve.cost(P0, rWad, s, mid);

            if (c <= eth) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }

        return low;
    }

    /**
     * @notice Core bonding curve: calculate ETH refund for selling dx tokens from supply s (scaled)
     * @param dx Tokens to sell in scaled units (whole tokens)
     * @param s Current supply in scaled units (whole tokens)
     * @return eth ETH refund in wei
     */
    function _solToEth(uint256 dx, uint256 s) internal pure returns (uint256 eth) {
        uint256 rWad = ExponentialCurve.toWad(NUM, DEN);
        return ExponentialCurve.refund(P0, rWad, s, dx);
    }

    /**
     * @notice Calculate tokens received for buying with `eth` at current supply
     * @dev Uses bonding curve with scaling: cost = K * (sol_scaled) * (2*supply_scaled + sol_scaled) / 2
     * Where sol_scaled = sol / 1e18 (whole tokens)
     */
    function buys(uint256 eth) public view returns (uint256 sol) {
        if (this == NOTHING) revert Nothing();
        uint256 s = totalSupply() / SCALE;
        uint256 solScaled = _ethToSol(eth, s);
        sol = solScaled * SCALE;
    }

    /**
     * @notice Buy tokens by sending ETH
     * @dev Mints new tokens according to bonding curve
     */
    function buy() public payable returns (uint256 sol) {
        if (this == NOTHING) revert Nothing();
        uint256 eth = msg.value;
        uint256 s = totalSupply() / SCALE;
        uint256 solScaled = _ethToSol(eth, s);
        sol = solScaled * SCALE;

        _mint(msg.sender, sol);
        emit Buy(this, eth, sol);
    }

    /**
     * @notice Calculate ETH refund for selling `sol` tokens at current supply
     * @dev Uses inverse bonding curve with scaling: refund = K * sol_scaled * (2*supply_scaled - sol_scaled) / 2
     * Capped to contract balance to handle rounding
     */
    function sells(uint256 sol) public view returns (uint256 eth) {
        if (this == NOTHING) revert Nothing();
        uint256 s = totalSupply() / SCALE;
        uint256 solScaled = sol / SCALE;
        if (solScaled > s) revert();
        eth = _solToEth(solScaled, s);
        // Cap to actual balance (rounding protection)
        uint256 balance = address(this).balance;
        if (eth > balance) eth = balance;
    }

    /**
     * @notice Sell tokens for ETH
     * @dev Burns tokens and returns ETH according to bonding curve
     */
    function sell(uint256 sol) external nonReentrant returns (uint256 eth) {
        eth = sells(sol);
        // Cap to actual balance (rounding protection)
        uint256 balance = address(this).balance;
        if (eth > balance) eth = balance;

        _burn(msg.sender, sol);
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

    /**
     * @notice Preview selling this token for another token
     */
    function sellsFor(ISolid that, uint256 sol) public view returns (uint256 thats) {
        uint256 eth = sells(sol);
        thats = that.buys(eth);
    }

    /**
     * @notice Sell this token for another token atomically
     */
    function sellFor(ISolid that, uint256 sol) external nonReentrant returns (uint256 thats) {
        uint256 eth = sells(sol);
        _burn(msg.sender, sol);
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
        }
    }
}
