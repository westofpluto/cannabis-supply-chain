// migrating the appropriate contracts
var GrowerRole = artifacts.require("./GrowerRole.sol");
var TesterRole = artifacts.require("./TesterRole.sol");
var DistributorRole = artifacts.require("./DistributorRole.sol");
var RetailerRole = artifacts.require("./RetailerRole.sol");
var ConsumerRole = artifacts.require("./ConsumerRole.sol");
var SupplyChainBase = artifacts.require("./SupplyChainBase.sol");
var SupplyChain = artifacts.require("./SupplyChain.sol");

module.exports = function(deployer) {
  deployer.deploy(GrowerRole);
  deployer.deploy(TesterRole);
  deployer.deploy(DistributorRole);
  deployer.deploy(RetailerRole);
  deployer.deploy(ConsumerRole);
  deployer.deploy(SupplyChainBase);
  deployer.deploy(SupplyChain);
};
