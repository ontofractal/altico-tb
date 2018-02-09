pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./TransferBurnToken.sol";


/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract WithdrawalVault is Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) public deposited;
  address public wallet;
  TransferBurnToken public tokenContract;
  uint256 public totalDonations;
  uint256 public withdrawnByOwners;
  uint256 public crowdsaleConversionRate;

  event Withdrawal(address indexed beneficiary, uint256 weiAmount);

  function WithdrawalVault(address _wallet, address _tokenContract, uint256 _crowdsaleConversionRate) public {
    require(_wallet != address(0));
    wallet = _wallet;
    tokenContract = TransferBurnToken(_tokenContract);
    totalDonations = 0;
    withdrawnByOwners = 0;
    crowdsaleConversionRate = _crowdsaleConversionRate;
  }

  function deposit(address investor, uint256 donationAmount) onlyOwner public payable {
    deposited[investor] = deposited[investor].add(msg.value.sub(donationAmount));
    totalDonations = totalDonations.add(donationAmount);
  }

  function withdraw(address investor, uint256 _value) public {
    deposited[investor] = deposited[investor] - _value;
    investor.transfer(_value);
    Withdrawal(investor, _value);
  }

  function withdrawBurnt(uint256 _value) public {
    uint256 initialSupply = tokenContract.INITIAL_SUPPLY();
    uint256 totalSupply = tokenContract.totalSupply();
    uint256 _totalTokensBurnt = initialSupply.sub(totalSupply);
    uint256 _maxWithdrawalValue = _totalTokensBurnt.div(crowdsaleConversionRate).sub(withdrawnByOwners);
    if (_value > _maxWithdrawalValue) {
      revert();
    }
    withdrawnByOwners = withdrawnByOwners + _value;
    wallet.transfer(_value);
  }

  function withdrawDonations(uint256 _value) public {
    require(wallet == msg.sender);
    totalDonations = totalDonations.sub(_value);
    wallet.transfer(_value);
  }

}
