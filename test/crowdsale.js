// testnet block generation time is set to 1 second

const Crowdsale = artifacts.require('./TransferBurnCrowdsale.sol')
const Token = artifacts.require('./TransferBurnToken.sol')
const Vault = artifacts.require('./WithdrawalVault.sol')

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

contract('TransferBurnCrowdsale', function ([owner, first, second, third]) {
  it("generic crowdsale and transfer burn flow should work", async function () {
    console.log("Owner address is:", owner)

    // Setting up crowdsale
    const startTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 1;
    console.log("Start time is:", startTime)
    const endTime = startTime + (86400); // 1 day
    console.log("End time is:", endTime)
    crowdsale = await Crowdsale.new(startTime, endTime, 1000, owner)

    // Logging contract addresses 
    const tokenAddress = await crowdsale.token()
    const vaultAddress = await crowdsale.vault()
    console.log("Crowdsale address is:", crowdsale.address)
    console.log("Token address is", tokenAddress)
    console.log("Vault address is", vaultAddress)

    // First account is buying tokens and donating
    await crowdsale.buyTokens.sendTransaction(first, 1e18, { from: first, value: 2e18 })

    // Verifying donation amount available at the vault
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_mine", params: [], id: 3 })
    const vault = Vault.at(vaultAddress)
    const vaultWallet = await vault.wallet()
    console.log("Vault wallet is:", vaultWallet.toString())
    const donations = (await vault.totalDonations()).toString()
    console.log("Total donations amount at the vault is:", donations)
    assert(donations === "1000000000000000000")

    // Verifying donations withdrawal by owner
    await vault.withdrawDonations.sendTransaction(1e18, {from: owner})
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_mine", params: [], id: 3 })
    const donationsAfterWithdrawal = (await vault.totalDonations()).toString()
    console.log("Total donations amount at the vault after withdrawal:", donationsAfterWithdrawal)
    assert(donationsAfterWithdrawal === "0")

    // Verifying token balance for first
    const token = Token.at(tokenAddress)
    const tokenOwner = await token.owner()
    console.log("Token owner is:", tokenOwner)
    assert(tokenOwner === crowdsale.address)
    await sleep(1000);

    // Verifying total token supply
    const tokenSupply = (await token.totalSupply()).toString()
    console.log("Token supply is:", tokenSupply)
    assert(tokenSupply === "1e+21")
    const firstBalance = await token.balanceOf(first)
    console.log(`First account owns this number of tokens: ${firstBalance.toString()}`)
    assert(firstBalance.toString() == "1e+21")

    // Buying tokens for third account
    await crowdsale.buyTokens.sendTransaction(third, 0, { from: third, value: 1e18 })
    await sleep(1000)

    // Validating token total supply 
    const tokenSupply2 = (await token.totalSupply()).toString()
    console.log("Token supply is:", tokenSupply2)
    assert(tokenSupply2 === "2e+21")

    // Travelling in the future to end crowdsale
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_increaseTime", params: [86400], id: 0 })

    // Testing transfers and transfer burn
    await token.transfer(second, "1234560000000", { from: first, value: "0x0", gas: 1000000 })
    await sleep(1000);
    const secondBalance = await token.balanceOf(second)
    console.log(`Second account now owns this number of tokens: ${secondBalance.toString()}`)
    assert(secondBalance.toString() === "1234560000000")
    const totalSupplyAfterFirstTransfer = (await token.totalSupply()).toString()
    console.log("Token supply after first transfer is:", totalSupplyAfterFirstTransfer)
    assert(totalSupplyAfterFirstTransfer === "1.99999999987777856e+21")
  });
});
