// Fetch the Storage contract data from the Storage.json file
var CurveFiManager = artifacts.require("./CurveFiManager.sol");
//var VaultManager = artifacts.require("./VaultManager.sol");

// JavaScript export
module.exports = function(deployer) {
    // Deployer is the Truffle wrapper for deploying
    // contracts to the network

    // Deploy the contract to the network
    /*deployer.deploy(VaultManager).then(function() {
        return deployer.deploy(CurveFiManager, VaultManager.address, "0x5ef30b9986345249bc32d8928B7ee64DE9435E39", "0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4", "0x19c0976f590D67707E62397C87829d896Dc0f1F1", "0x9759A6Ac90977b93B58547b4A71c78317f391A28", "0xA191e578a6736167326d05c119CE0c90849E84B7", "0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
    });
    */
   return deployer.deploy(CurveFiManager, "0x5ef30b9986345249bc32d8928B7ee64DE9435E39", "0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4", "0x19c0976f590D67707E62397C87829d896Dc0f1F1", "0x9759A6Ac90977b93B58547b4A71c78317f391A28", "0xA191e578a6736167326d05c119CE0c90849E84B7", "0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");

}
