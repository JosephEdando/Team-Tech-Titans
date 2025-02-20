require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const {ALCHEMY_API_KEY, DEPLOYER_PRIVATE_KEY} = process.env

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    arbitrumSepolia: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [DEPLOYER_PRIVATE_KEY],
    },
  }
};