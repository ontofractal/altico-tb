const Token = artifacts.require('./TransferBurnToken.sol')

contract('token', function([owner]) {
  it("transfer burn value should be correct", async function() {
    const token = await Token.new()
    const toBurn = (await token.getTransferBurnValue(1000)).toString()
    assert(toBurn === "100")
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_increaseTime", params: [86400], id: 0 })
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_mine", params: [], id: 1 })
    const toBurn2 = (await token.getTransferBurnValue(1000)).toString()
    assert(toBurn2 === "99")
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_increaseTime", params: [10 * 86400], id: 2 })
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_mine", params: [], id: 3 })
    const toBurn3 = (await token.getTransferBurnValue(1000)).toString()
    assert(toBurn3 === "89")
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_increaseTime", params: [10 * 86400], id: 4 })
    await web3.currentProvider.send({ jsonrpc: "2.0", method: "evm_mine", params: [], id: 5 })
    const toBurn4 = (await token.getTransferBurnValue(1000)).toString()
    assert(toBurn4 === "79")
  });
});
