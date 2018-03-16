let Owned = artifacts.require('Owned');
// let TokenERC20 = artifacts.require('TokenERC20');
// let MyAdvancedToken = artifacts.require('MyAdvancedToken');
let OmniToken = artifacts.require('OmniToken');

module.exports = function(deployer) {
  deployer.deploy(Owned);
  // deployer.link(Owned, MyAdvancedToken);
  // deployer.deploy(TokenERC20, 1000000000, 'Chaos Token', 'CHAOS');
  // deployer.link(TokenERC20, MyAdvancedToken);
  // deployer.deploy(MyAdvancedToken, 1000000000, 'Chaos Token', 'CHAOS');
  deployer.link(Owned, OmniToken);
  deployer.deploy(OmniToken, 'Omnipotent', 'OMNI');
};
