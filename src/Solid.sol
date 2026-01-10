// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {ERC20} from "erc20/ERC20.sol";
import {Clones} from "clones/Clones.sol";
import {ReentrancyGuardTransient} from "reentrancy/ReentrancyGuardTransient.sol";

contract Solid is ISolid, ERC20, ReentrancyGuardTransient {
    uint256 constant K = 1e9;

    ISolid public immutable NOTHING = this;

    constructor() ERC20("", "NOTHING") {}

    /**
     * @notice Calculate tokens received for buying with `eth` at current supply
     * @dev Uses bonding curve: sol = sqrt(s² + 2*eth/K) - s
     */
    function buys(uint256 eth) public view returns (uint256 sol) {
        if (this == NOTHING) revert Nothing();
        uint256 s = totalSupply();
        uint256 s2 = s * s;
        uint256 discriminant = s2 + (2 * eth) / K;
        sol = sqrt(discriminant) - s;
    }

    /**
     * @notice Buy tokens by sending ETH
     * @dev Mints new tokens according to bonding curve
     */
    function buy() public payable returns (uint256 sol) {
        if (this == NOTHING) revert Nothing();
        uint256 eth = msg.value;
        uint256 s = totalSupply();

        // Solve: eth = K * sol * (2*s + sol) / 2
        // Using quadratic formula: sol = sqrt(s² + 2*eth/K) - s
        uint256 s2 = s * s;
        uint256 discriminant = s2 + (2 * eth) / K;
        sol = sqrt(discriminant) - s;

        _mint(msg.sender, sol);
        emit Buy(this, eth, sol);
    }

    /**
     * @notice Calculate ETH refund for selling `sol` tokens at current supply
     * @dev Uses inverse bonding curve: refund = K * sol * (2*supply - sol) / 2
     */
    function sells(uint256 sol) public view returns (uint256 eth) {
        if (this == NOTHING) revert Nothing();
        uint256 s = totalSupply();
        if (sol > s) revert();
        eth = (K * sol * (2 * s - sol)) / 2;
    }

    /**
     * @notice Sell tokens for ETH
     * @dev Burns tokens and returns ETH according to bonding curve
     */
    function sell(uint256 sol) external nonReentrant returns (uint256 eth) {
        eth = sells(sol);
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

    /**
     * @notice Integer square root using Babylonian method
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
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
