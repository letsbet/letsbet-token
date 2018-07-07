const Web3 = require('web3');
var contracts = require("./contracts.js");
var config = require('./truffle.js');
var moment = require('moment');
var BigNumber = require('bignumber.js');

var web3 = new Web3();
var auctionAddress = config.auction.contract.address;
var tokenAddress = config.auction.contract.tokenAddress;
var dutchAuction = new contracts.DutchAuction(auctionAddress);

var params = process.argv.slice(2);
var command = params[0];

switch (command) {
    case 'setup':
        console.log("Setup dutch auction with token address: " + tokenAddress);
        dutchAuction.setup(tokenAddress);
    break;
    case 'start':
        console.log("Start dutch auction with  address: " + auctionAddress);
        dutchAuction.start();
    break;
    case 'finalize':
        console.log("Finalize dutch auction with token address: " + auctionAddress);
        dutchAuction.finalize(auctionAddress);
    break;
}
