// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Stakeable ERC20 Token with Time-based Points
/// @notice ERC20 token that supports owner minting, user burn, and simple staking
/// that accrues non-transferable points over time while tokens are staked.
contract StakeToken is ERC20, ERC20Burnable, Ownable {
    /// @dev Points are accrued at a fixed rate of 1 point per token per hour.
    uint256 public constant POINTS_RATE_NUMERATOR = 1; // 1 point
    uint256 public constant POINTS_RATE_PERIOD = 1 hours; // per hour

    /// @dev amount of tokens each user has staked (held by this contract)
    mapping(address => uint256) private userStakedAmount;
    /// @dev accumulated points that have been realized (not including pending since last update)
    mapping(address => uint256) private userRealizedPoints;
    /// @dev last timestamp when rewards for the user were updated
    mapping(address => uint256) private userLastUpdateTs;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event PointsClaimed(address indexed user, uint256 points);

    constructor(string memory name_, string memory symbol_, address initialOwner)
        ERC20(name_, symbol_)
        Ownable(initialOwner)
    {}

    /// @notice Mint new tokens to an address. Only owner can mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Stake tokens to start accruing points over time.
    /// @dev Tokens are transferred to this contract. Use `unstake` to withdraw.
    function stake(uint256 amount) external {
        require(amount > 0, "StakeToken: amount=0");
        _updateRewards(msg.sender);
        _transfer(msg.sender, address(this), amount);
        userStakedAmount[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    /// @notice Unstake tokens previously staked.
    function unstake(uint256 amount) external {
        require(amount > 0, "StakeToken: amount=0");
        uint256 staked = userStakedAmount[msg.sender];
        require(staked >= amount, "StakeToken: insufficient staked");
        _updateRewards(msg.sender);
        userStakedAmount[msg.sender] = staked - amount;
        _transfer(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /// @notice Claim accumulated points and reset the counter.
    /// @return points Amount of points claimed
    function claimPoints() external returns (uint256 points) {
        _updateRewards(msg.sender);
        points = userRealizedPoints[msg.sender];
        userRealizedPoints[msg.sender] = 0;
        emit PointsClaimed(msg.sender, points);
    }

    /// @notice View the user's total points including pending since last update.
    function pointsOf(address user) external view returns (uint256) {
        return userRealizedPoints[user] + _pendingPoints(user);
    }

    /// @notice View the amount of tokens the user has currently staked.
    function stakedOf(address user) external view returns (uint256) {
        return userStakedAmount[user];
    }

    /// @dev Calculate pending points since the last update based on staked amount and time elapsed.
    function _pendingPoints(address user) internal view returns (uint256) {
        uint256 lastTs = userLastUpdateTs[user];
        if (lastTs == 0) {
            return 0;
        }
        uint256 staked = userStakedAmount[user];
        if (staked == 0) {
            return 0;
        }
        uint256 elapsed = block.timestamp - lastTs;
        // points = staked * rate * elapsed, where rate = 1 point per token per hour
        // We avoid fractions by dividing by period.
        return (staked * POINTS_RATE_NUMERATOR * elapsed) / POINTS_RATE_PERIOD;
    }

    /// @dev Update realized points and timestamp for a user.
    function _updateRewards(address user) internal {
        uint256 lastTs = userLastUpdateTs[user];
        if (lastTs == 0) {
            // Initialize timestamp at first interaction to start accrual going forward
            userLastUpdateTs[user] = block.timestamp;
            return;
        }
        uint256 pending = _pendingPoints(user);
        if (pending > 0) {
            userRealizedPoints[user] += pending;
        }
        userLastUpdateTs[user] = block.timestamp;
    }
}


