pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";


/**
 * @title LetsbetToken Token
 * @dev ERC20 LetsbetToken Token (XBET)
 */
contract LetsbetToken is PausableToken, BurnableToken {

    string public constant name = "Letsbet Token";
    string public constant symbol = "XBET";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 100000000 * 10**uint256(decimals); // 100 000 000 (100m)
    uint256 public constant TEAM_TOKENS = 18000000 * 10**uint256(decimals); // 18 000 000 (18m)
    uint256 public constant BOUNTY_TOKENS = 5000000 * 10**uint256(decimals); // 5 000 000 (5m)
    uint256 public constant AUCTION_TOKENS = 77000000 * 10**uint256(decimals); // 77 000 000 (77m)

    event Deployed(uint indexed _totalSupply);

    /**
    * @dev LetsbetToken Constructor
    */
    function LetsbetToken(
        address auctionAddress,
        address walletAddress,
        address bountyAddress)
        public
    {

        require(auctionAddress != 0x0);
        require(walletAddress != 0x0);
        require(bountyAddress != 0x0);
        
        totalSupply_ = INITIAL_SUPPLY;

        balances[auctionAddress] = AUCTION_TOKENS;
        balances[walletAddress] = TEAM_TOKENS;
        balances[bountyAddress] = BOUNTY_TOKENS;

        Transfer(0x0, auctionAddress, balances[auctionAddress]);
        Transfer(0x0, walletAddress, balances[walletAddress]);
        Transfer(0x0, bountyAddress, balances[bountyAddress]);

        Deployed(totalSupply_);
        assert(totalSupply_ == balances[auctionAddress] + balances[walletAddress] + balances[bountyAddress]);
    }
}