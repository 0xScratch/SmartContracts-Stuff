const Vending_Machine = artifacts.require("Vending_Machine");

module.exports = function (deployer) {
    deployer.deploy(Vending_Machine);
};