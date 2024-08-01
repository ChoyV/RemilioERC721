require('@nomiclabs/hardhat-waffle'); // For compiling and deploying contracts
require('@nomiclabs/hardhat-ethers'); // For using ethers.js with Hardhat
require('@nomiclabs/hardhat-etherscan'); // For verifying contracts on Etherscan

module.exports = {
  solidity: {
    version: "0.8.19", // Specify the Solidity version
    settings: {
      optimizer: {
        enabled: true, // Enable the optimizer
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      // Hardhat local network configuration
    },
    localhost: {
      url: 'http://127.0.0.1:8545' // Localhost network configuration
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/YOUR_INFURA_PROJECT_ID`, // Rinkeby test network
      accounts: [`0x${YOUR_PRIVATE_KEY}`] // Replace with your private key
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID`, // Mainnet network
      accounts: [`0x${YOUR_PRIVATE_KEY}`] // Replace with your private key
    }
  },
  etherscan: {
    apiKey: "YOUR_ETHERSCAN_API_KEY" // API key for Etherscan verification
  }
};
