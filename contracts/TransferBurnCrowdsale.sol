pragma solidity ^0.4.18;

import "./Crowdsale.sol";
import "./SafeMath.sol";
import "./WithdrawalVault.sol";
import "./TransferBurnToken.sol";

contract TransferBurnCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  uint deploymentBlock;
  WithdrawalVault public vault;
  TransferBurnToken public token;
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function TransferBurnCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    wallet = _wallet;
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    token = createTokenContract();
    vault = new WithdrawalVault(wallet, token, rate);
  }

  function () external payable {
    buyTokens(msg.sender, 0);
  }

  // low level token purchase function
  function buyTokens(address beneficiary, uint256 _donationAmount) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value.sub(_donationAmount);

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds(_donationAmount);
  }

  function createTokenContract() internal returns (TransferBurnToken) {
    return new TransferBurnToken();
  }

  function withdraw(uint256 _value) public returns (bool) {
    assert(now > endTime);
    uint256 _tokens = _value.mul(rate);
    token.withdrawalBurn(msg.sender, _tokens);
    vault.withdraw(msg.sender, _value);
  }

  function forwardFunds(uint256 _donationAmount) internal {
     vault.deposit.value(msg.value)(msg.sender, _donationAmount);
  }

  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

}
