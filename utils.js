var crypto = require('crypto');
var algorithm = 'aes-256-ctr';
var iv = crypto.randomBytes(16);

module.exports = {
    shuffle(array){
        var j, temp, i;
        for (i = array.length - 1; i > 0; i--) {
            j = Math.floor(Math.random() * (i + 1));
            temp = array[i];
            array[i] = array[j];
            array[j] = temp;
        }
    },
    randomElement(array){
        return array[Math.floor(Math.random() * array.length)];
    },
    randomInt(min,max){
        return Math.floor(Math.random() * (max - min + 1)) + min; 
    },
    randomNumber(min,max){
        return (Math.random() * (max - min) + min); 
    }
    ,randomPrice(min,max){
        var number = this.randomNumber(min,max);
        return parseFloat(number).toFixed(2);  
    },
    percentage(num, percentage) {
         return ((num/100) * percentage).toFixed(2);
    },
    encrypt(text,password){
        var cipher = crypto.createCipher(algorithm,password)
        var crypted = cipher.update(text,'utf8','hex')
        crypted += cipher.final('hex');
        return crypted;
    },
    decrypt(text,password){
        var decipher = crypto.createDecipher(algorithm,password)
        var dec = decipher.update(text,'hex','utf8')
        dec += decipher.final('utf8');
        return dec;
    },
    base64Encode(text){
        return new Buffer(text).toString('base64');
    },
    base64Decode(text){
        return new Buffer(text, 'base64').toString('ascii');
    },
    parse(str) {
        var args = [].slice.call(arguments, 1),
            i = 0;
    
        return str.replace(/%s/g, function() {
            return args[i++];
        });
    }
};

Array.prototype.insert = function ( index, item ) {
    this.splice( index, 0, item );
};

Date.unix = function(unixTime){
	return new Date(unixTime * 1000);
}