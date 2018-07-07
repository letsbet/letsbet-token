const Web3 = require('web3');
var web3 = new Web3();
var ethereumjsWallet = require('ethereumjs-wallet');
var HDWalletProvider = require("truffle-hdwallet-provider");
var utils = require("./utils.js");
var moment = require('moment');

var mnemonic=""
var ownerAddress="";
var privateKey="";
var providerUrl = "https://mainnet.infura.io/metamask";

console.log("Wallet Address: " + ownerAddress);

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*",
      from: ownerAddress,
    },
    ropsten: {
       network_id: 3,    // Official ropsten network id
       provider: new HDWalletProvider(mnemonic, providerUrl), // Use our custom provider
       from: ownerAddress,
       gas: 4700000,
       gasPrice: web3.utils.toWei("21", "gwei")
    },
    main: {
      network_id: 1,    // Official mainnet network id
      provider: new HDWalletProvider(mnemonic, providerUrl), // Use our custom provider
      from: ownerAddress,
      gas: 4700000,
      gasPrice: web3.utils.toWei("80", "gwei")
   }
  },
  keys: {
    private: new Buffer(privateKey, 'hex')
  },
  provider: {
    url:providerUrl
  },
  auction: {
    contract:{
      address:'0x50B877909Ee8362F77BcD5e64d2DfEadE923286A',
      tokenAddress:'0x51001930DFC4a066beaa2788248ac457c09a6Ebb',
      owner: ownerAddress,
      walletAddress: '0x68e683c1fe50e557014bac3a0529dff7b7ca3bbb',
      bountyAddress: '0x4e65bdd691d6aba5726aba1215c131a282e8006f',
      priceStart:150000000000000,
      priceDecreaseRate:180000000,
      endTime:moment.utc('2018-08-31 14:00:00', "YYYY-MM-DD HH:mm:ss").unix() 
    }
  }
};

