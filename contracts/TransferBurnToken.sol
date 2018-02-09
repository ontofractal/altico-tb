pragma solidity ^0.4.18;

import "./MintableToken.sol";

contract TransferBurnToken is MintableToken {
  using SafeMath for uint256;
  string public name = "XTB";
  string public symbol = "XTB";
  uint public decimals = 2;
  uint public INITIAL_SUPPLY = 1000000;
  uint256 public deploymentTime;

  event Burn(address indexed burner, uint256 value);

  function TransferBurnToken()  public payable {
    deploymentTime = now;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    uint256 _tokensToBurn = getTransferBurnValue(_value);
    burn(_tokensToBurn);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }

  function withdrawalBurn(address _investor, uint256 _value) onlyOwner public {
    require(_investor != address(0));
    require(_value <= balances[_investor]);

    balances[_investor] = balances[_investor].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(_investor, _value);
  }

  function getTransferBurnValue(uint256 _value) public view returns (uint256) {
    uint256 _daysDelta = (now.sub(deploymentTime)).div(86400);
    uint256 _multiplicator = 100 - _daysDelta;
    if (_multiplicator < 1) {
      _multiplicator = 1;
    }
    return _value.mul(_multiplicator).div(1000);
  }
}
