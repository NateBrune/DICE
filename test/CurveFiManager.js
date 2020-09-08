const { BN, ether, balance } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { asyncForEach } = require('./utils');

const CurveFiManager = artifacts.require("CurveFiManager");
//const VaultManager = artifacts.require("VaultManager");

const daiABI = require("@studydefi/money-legos/erc20/abi/ERC20");

// ABI
//const daiABI = require('./abi/dai');

// userAddress must be unlocked using --unlock ADDRESS
const userAddress = '0x9eb7f2591ed42dee9315b6e2aaf21ba85ea69f8c';
const daiAddress = '0x6b175474e89094c44da98b954eedeac495271d0f';
var ourAddress = '';
const daiContract = new web3.eth.Contract(daiABI, daiAddress);

contract('Test CurveFi Short', async accounts => {
  it('should send ether to the DAI address', async () => {
    // Send 0.1 eth to userAddress to have gas to send an ERC20 tx.
    ourAddress = accounts[0];
    await web3.eth.sendTransaction({
      from: accounts[0],
      to: userAddress,
      value: ether('0.1')
    });
    const ethBalance = await balance.current(userAddress);
    expect(new BN(ethBalance)).to.be.bignumber.least(new BN(ether('0.1')));
  });

  it('should mint DAI for our first 2 generated accounts', async () => {
    // Get 100,000 DAI for first 5 accounts
    await asyncForEach(accounts.slice(0, 2), async account => {
      // daiAddress is passed to ganache-cli with flag `--unlock`
      // so we can use the `transfer` method
      await daiContract.methods
        .transfer(account, ether('100000').toString())
        .send({ from: userAddress, gasLimit: 800000 });
      const daiBalance = await daiContract.methods.balanceOf(account).call();
      expect(new BN(daiBalance)).to.be.bignumber.least(ether('100000'));
    });
  });

  it('Build Maker proxy', async () => {
    let curve = await CurveFiManager.deployed();
    let proxy = await curve.buildProxy();
    let proxyAddy = await curve._ourProxyAddress();
    console.log(proxyAddy);
  });

  it('Execute proxy contract swap', async () => {
    let curve = await CurveFiManager.deployed();
    //let vaultManager = await VaultManager.deployed();
    await daiContract.methods
        .transfer(curve.address, ether('1500').toString())
        .send({ from: ourAddress, gasLimit: 800000 });
    const daiBalance = await daiContract.methods.balanceOf(curve.address).call();
    expect(new BN(daiBalance)).to.be.bignumber.least(ether('1500'));
    var approved = await curve.getApproval();
    if(!approved){
      console.log("Approval failed!");
      return false;
    }

    await curve.swapDaiToUsdc(ether('1000'));
  });

  it('Open Maker vault', async () => {
    let curve = await CurveFiManager.deployed();
    let vault = await curve.openVault();
    console.log(vault);
  });


  it('Should short Dai with 10,000 Dai and 10x leverage', async () => {
    let curve = await CurveFiManager.deployed();
    //let vaultManager = await VaultManager.deployed();
    await daiContract.methods
        .transfer(curve.address, ether('10000').toString())
        .send({ from: ourAddress, gasLimit: 800000 });
    const daiBalance = await daiContract.methods.balanceOf(curve.address).call();
    expect(new BN(daiBalance)).to.be.bignumber.least(ether('10000'));
    //var approvetx = await curve.getApproval();
    //var proxytx = await curve.buildProxy();
    //var vaulttx = await curve.openVault();
    await curve.initateFlashLoan('0x00');
  });
});