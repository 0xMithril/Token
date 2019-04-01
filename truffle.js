require('dotenv').config()
var Web3 = require('web3')
const HDWalletProvider = require("truffle-hdwallet-provider")

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    bitchain: {
      host: "68.183.26.29",
      port: 8547,
      network_id: "*",
      from: "0x2b833b6ae9a5f46667c923f9509e0389c1f4c367",
      //gas: 10000000,
      gasPrice: 1
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(process.env.MNEMONIC, "https://rinkeby.infura.io/WugAgm82bU9X5Oh2qltc")
      },
      network_id: 3,
      gas: 7000000      //make sure this gas allocation isn't over 4M, which is the max
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(process.env.MNEMONIC, "https://ropsten.infura.io/WugAgm82bU9X5Oh2qltc")
      },
      network_id: 3,
      gas: 4000000      //make sure this gas allocation isn't over 4M, which is the max
    },
    sokol: {
      provider: function() {
        return new HDWalletProvider(process.env.MNEMONIC, "https://sokol.poa.network")
      },
      network_id: 77,
      from: "0x2b833b6ae9a5f46667c923f9509e0389c1f4c367"
    },
  },

  compilers: {
    solc: {
      version: "0.4.24"
    }
  }
};

/*
module.exports = {
   networks: {
     development: {
	   host: "127.0.0.1",
	   port: 7545,
	   network_id: "*" // Match any network id
    }
 }
};
*/