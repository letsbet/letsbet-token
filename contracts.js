const Web3 = require('web3');
var fs = require('fs');
var config = require('./truffle.js');
var request = require('request');
var Tx = require('ethereumjs-tx');


var jsonDutchAuction = JSON.parse(fs.readFileSync('./build/contracts/DutchAuction.json'));
var jsonToken = JSON.parse(fs.readFileSync('./build/contracts/LetsbetToken.json'));

var txSender = config.auction.contract.owner;


var web3 = new Web3();
var httpProvider = config.provider.url;
console.log(httpProvider);
web3.setProvider(new Web3.providers.HttpProvider(httpProvider));

function DutchAuction(address){
    this.address = address;
    this.txManager = new TxManager();
}

DutchAuction.prototype._contract = function(){
    var self = this;
    var abi = jsonDutchAuction.abi;
    return new web3.eth.Contract(abi,self.address);
}

DutchAuction.prototype.setup = function(tokenAddress){

    var self = this;
    var contract = self._contract();
  
    console.log("Setup XBET token contract address: " + tokenAddress);
    self.txManager.nextNonce(txSender,function (nonceNumber) {
        console.log(nonceNumber);

        var setupData = contract.methods.setup(tokenAddress).encodeABI();
        var value = web3.utils.toWei("0",'ether');
        var gasPrice =  web3.utils.toWei("60".toString(),'gwei'); 

        var rawTx = {
            nonce: web3.utils.toHex(nonceNumber),
            from: txSender,
            gasPrice: web3.utils.toHex(gasPrice),
            gasLimit: web3.utils.toHex(1500000),
            to: self.address,
            value: web3.utils.toHex(value),
            data: setupData
        }

        self.txManager.signTransaction(rawTx);
    });
}

DutchAuction.prototype.finalize = function(){

    var self = this;
    var contract = self._contract();
  
    self.txManager.nextNonce(txSender,function (nonceNumber) {
        console.log(nonceNumber);

        var finalizeData = contract.methods.finalizeAuction().encodeABI();
        var value = web3.utils.toWei("0",'ether');
        var gasPrice =  web3.utils.toWei("21".toString(),'gwei'); 

        var rawTx = {
            nonce: web3.utils.toHex(nonceNumber),
            from: txSender,
            gasPrice: web3.utils.toHex(gasPrice),
            gasLimit: web3.utils.toHex(1500000),
            to: self.address,
            value: web3.utils.toHex(value),
            data: finalizeData
        }

        self.txManager.signTransaction(rawTx);
    });
}

DutchAuction.prototype.start = function(){
    var self = this;
    var contract = self._contract();
  
    console.log("Start auction");
    self.txManager.nextNonce(txSender,function (nonceNumber) {
        console.log("Nonce" + nonceNumber);

        var startData = contract.methods.startAuction().encodeABI();
        var value = web3.utils.toWei("0",'ether');
        var gasPrice =  web3.utils.toWei("80".toString(),'gwei'); 

        var rawTx = {
            nonce: web3.utils.toHex(nonceNumber),
            from: txSender,
            gasPrice: web3.utils.toHex(gasPrice),
            gasLimit: web3.utils.toHex(1500000),
            to: self.address,
            value: web3.utils.toHex(value),
            data: startData
        }

        self.txManager.signTransaction(rawTx);
    });
}

DutchAuction.prototype.remainingFunds = function(callback){
    var self = this;
    var contract = self._contract();
    contract.methods.missingFundsToEndAuction().call(function(error,result){
        callback(error,result);
    });
}

DutchAuction.prototype.endTimeOfBids = function(callback){
    var self = this;
    var contract = self._contract();
    contract.methods.endTimeOfBids().call(function(error,result){
        callback(error,result);
    });
}


DutchAuction.prototype.price = function(callback){
    var self = this;
    var contract = self._contract();
    contract.methods.price().call(function(error,result){
        callback(error,result);
    });
}

function TxManager(){
    this.nonceMap ={};
}

TxManager.prototype.signTransaction = function(rawTx,key){
    console.log(rawTx);

    var privateKey = key || config.keys.private;
    var tx = new Tx(rawTx);
    tx.sign(privateKey);

    var serializedTx = tx.serialize();
    web3.eth.sendSignedTransaction('0x' + serializedTx.toString('hex')).on('receipt', console.log);
}


TxManager.prototype.nextNonce = function (address, callback) {
    var self = this;
    web3.eth.getTransactionCount(address).then(function (nonce) {
        var lastNonce = self.nonceMap[address];
        
        if(lastNonce){
            while (nonce <= lastNonce) {
                nonce++;
            }
        }
        self.nonceMap[address]=nonce;
        callback(nonce);
    });
}



module.exports = {
    DutchAuction: DutchAuction
};