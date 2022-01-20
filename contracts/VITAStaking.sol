//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStaking.sol";

contract VITAStaking is IStaking, ReentrancyGuard, Ownable {
    mapping(address => uint256) private _stakedBalances;
    mapping(address => uint256) private _unlockTimes;

    address private tokenAddress;
    uint256 totalStakedBalance;
    bool shutdown=false;

    event StakeChanged(address staker, uint256 newStakedBalance);
    event UnlockTimeIncreased(address staker, uint256 newUnlockBlock);
    event EmergencyShutdown(address calledBy, uint256 shutdownBlock);

    modifier notShutdown() {
        require(!shutdown, "cannot be called after shutdown");
        _;
    }

    constructor(address _token) {
        tokenAddress = _token;
    }

    /**
     * @dev returns address of the token that can be staked
     *
     * @return the address of the token contract
     */
    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    /**
     * @dev Gets staker's staked balance 
     * @param staker                 The staker's address
     * @return (uint) staked token balance
     */
    function getStakedBalance(address staker) external view override returns(uint256) {
        return _stakedBalances[staker];
    }

    /**
     * @dev Gets staker's unlock time
     * @param staker                 The staker's address
     * @return (uint) staker's unlock time in blocks
     */
    function getUnlockTime(address staker) external view override returns(uint256) {
        return _unlockTimes[staker];
    }

    /**
     * @dev returns if staking contract is shutdown or not
     */
    function isShutdown() public view override returns(bool) {
        return shutdown;
    }

    /**
     * @dev allows a user to stake and to increase their stake
     * @param amount the uint256 amount of native token being staked/added
     * @notice user must first approve staking contract for at least the amount
     */
    function stake(uint256 amount, uint256 unlockTime) external notShutdown override {
        IERC20 tokenContract = IERC20(tokenAddress);
        require(tokenContract.balanceOf(msg.sender) >= amount, "Amount higher than user's balance");
        require(tokenContract.allowance(msg.sender, address(this)) >= amount, 'Approved allowance too low');
        require(
            tokenContract.transferFrom(msg.sender, address(this), amount),
            "staking tokens failed"
        );
        totalStakedBalance += amount;
        _unlockTimes[msg.sender] = unlockTime; //TODO: add checks for unlock time in future, and within limits
        _stakedBalances[msg.sender] += amount;

        emit StakeChanged(msg.sender, _stakedBalances[msg.sender]);
    }

    /**
     * @dev allows a user to withdraw their unlocked tokens
     * @param amount the uint256 amount of native token being withdrawn
     */
    function withdraw(uint256 amount) external override {
        if(!shutdown){
            require(_unlockTimes[msg.sender] < block.number, "Tokens not unlocked yet");
        }
        require(
            _stakedBalances[msg.sender] >= amount,
            "Insufficient staked balance"
        );
        require(totalStakedBalance >= amount, "insufficient funds in contract");

        // Send unlocked tokens back to user
        totalStakedBalance -= amount;
        _stakedBalances[msg.sender] -= amount;
        IERC20 tokenContract = IERC20(tokenAddress);
        require(tokenContract.transfer(msg.sender, amount), "withdraw failed");
    }

    function emergencyShutdown(address admin) external onlyOwner notShutdown nonReentrant override {
        // when shutdown = true, it skips the locktime require in withdraw
        // so all users get their tokens unlocked immediately
        shutdown = true;
        emit EmergencyShutdown(admin, block.number);
    }
}
