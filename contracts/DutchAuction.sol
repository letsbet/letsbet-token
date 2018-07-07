pragma solidity ^0.4.17;

import './LetsbetToken.sol';

/// @title Dutch auction contract - distribution of a fixed number of tokens using an auction.
/// The contract code is inspired by the Gnosis and Raiden auction contract. Main difference is that the
/// auction ends if a fixed number of tokens was sold.
contract DutchAuction {
    
	/*
     * Auction for the XBET Token.
     */
    // Wait 7 days after the end of the auction, before anyone can claim tokens
    uint constant public TOKEN_CLAIM_WAITING_PERIOD = 7 days;

    LetsbetToken public token;
    address public ownerAddress;
    address public walletAddress;

    // Starting price in WEI
    uint public startPrice;

    // Divisor constant; e.g. 180000000
    uint public priceDecreaseRate;

    // For calculating elapsed time for price
    uint public startTime;

    uint public endTimeOfBids;

    // When auction was finalized
    uint public finalizedTime;
    uint public startBlock;

    // Keep track of all ETH received in the bids
    uint public receivedWei;

    // Keep track of cumulative ETH funds for which the tokens have been claimed
    uint public fundsClaimed;

    uint public tokenMultiplier;

    // Total number of Rei (XBET * tokenMultiplier) that will be auctioned
    uint public tokensAuctioned;

    // Wei per XBET
    uint public finalPrice;

    // Bidder address => bid value
    mapping (address => uint) public bids;


    Stages public stage;

    /*
     * Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TokensDistributed
    }

    /*
     * Modifiers
     */
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == ownerAddress);
        _;
    }
	
    /*
     * Events
     */
    event Deployed(
        uint indexed _startPrice,
        uint indexed _priceDecreaseRate
    );
    
	event Setup();
    
	event AuctionStarted(uint indexed _startTime, uint indexed _blockNumber);
    
	event BidSubmission(
        address indexed sender,
        uint amount,
        uint missingFunds,
        uint timestamp
    );
    
	event ClaimedTokens(address indexed _recipient, uint _sentAmount);
    
	event AuctionEnded(uint _finalPrice);
    
	event TokensDistributed();

    /// @dev Contract constructor function sets the starting price, divisor constant and
    /// divisor exponent for calculating the Dutch Auction price.
    /// @param _walletAddress Wallet address to which all contributed ETH will be forwarded.
    /// @param _startPrice High price in WEI at which the auction starts.
    /// @param _priceDecreaseRate Auction price decrease rate.
    /// @param _endTimeOfBids last time bids could be accepted.
    function DutchAuction(
        address _walletAddress,
        uint _startPrice,
        uint _priceDecreaseRate,
        uint _endTimeOfBids) 
    public
    {
        require(_walletAddress != 0x0);
        walletAddress = _walletAddress;

        ownerAddress = msg.sender;
        stage = Stages.AuctionDeployed;
        changeSettings(_startPrice, _priceDecreaseRate,_endTimeOfBids);
        Deployed(_startPrice, _priceDecreaseRate);
    }

    function () public payable atStage(Stages.AuctionStarted) {
        bid();
    }

    /// @notice Set `_tokenAddress` as the token address to be used in the auction.
    /// @dev Setup function sets external contracts addresses.
    /// @param _tokenAddress Token address.
    function setup(address _tokenAddress) public isOwner atStage(Stages.AuctionDeployed) {
        require(_tokenAddress != 0x0);
        token = LetsbetToken(_tokenAddress);

        // Get number of Rei (XBET * tokenMultiplier) to be auctioned from token auction balance
        tokensAuctioned = token.balanceOf(address(this));

        // Set the number of the token multiplier for its decimals
        tokenMultiplier = 10 ** uint(token.decimals());

        stage = Stages.AuctionSetUp;
        Setup();
    }

    /// @dev Changes auction price function parameters before auction is started.
    /// @param _startPrice Updated start price.
    /// @param _priceDecreaseRate Updated price decrease rate.
    function changeSettings(
        uint _startPrice,
        uint _priceDecreaseRate,
        uint _endTimeOfBids
        )
        internal
    {
        require(stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp);
        require(_startPrice > 0);
        require(_priceDecreaseRate > 0);
        require(_endTimeOfBids > now);
        
        endTimeOfBids = _endTimeOfBids;
        startPrice = _startPrice;
        priceDecreaseRate = _priceDecreaseRate;
    }


    /// @notice Start the auction.
    /// @dev Starts auction and sets startTime.
    function startAuction() public isOwner atStage(Stages.AuctionSetUp) {
        stage = Stages.AuctionStarted;
        startTime = now;
        startBlock = block.number;
        AuctionStarted(startTime, startBlock);
    }

    /// @notice Finalize the auction - sets the final XBET token price and changes the auction
    /// stage after no bids are allowed anymore.
    /// @dev Finalize auction and set the final XBET token price.
    function finalizeAuction() public isOwner atStage(Stages.AuctionStarted) {
        // Missing funds should be 0 at this point
        uint missingFunds = missingFundsToEndAuction();
        require(missingFunds == 0 || now > endTimeOfBids);

        // Calculate the final price = WEI / XBET = WEI / (Rei / tokenMultiplier)
        // Reminder: tokensAuctioned is the number of Rei (XBET * tokenMultiplier) that are auctioned
        finalPrice = tokenMultiplier * receivedWei / tokensAuctioned;

        finalizedTime = now;
        stage = Stages.AuctionEnded;
        AuctionEnded(finalPrice);

        assert(finalPrice > 0);
    }

    /// --------------------------------- Auction Functions ------------------


    /// @notice Send `msg.value` WEI to the auction from the `msg.sender` account.
    /// @dev Allows to send a bid to the auction.
    function bid()
        public
        payable
        atStage(Stages.AuctionStarted)
    {
        require(msg.value > 0);
        assert(bids[msg.sender] + msg.value >= msg.value);

        // Missing funds without the current bid value
        uint missingFunds = missingFundsToEndAuction();

        // We require bid values to be less than the funds missing to end the auction
        // at the current price.
        require(msg.value <= missingFunds);

        bids[msg.sender] += msg.value;
        receivedWei += msg.value;

        // Send bid amount to wallet
        walletAddress.transfer(msg.value);

        BidSubmission(msg.sender, msg.value, missingFunds,block.timestamp);

        assert(receivedWei >= msg.value);
    }

    /// @notice Claim auction tokens for `msg.sender` after the auction has ended.
    /// @dev Claims tokens for `msg.sender` after auction. To be used if tokens can
    /// be claimed by beneficiaries, individually.
    function claimTokens() public atStage(Stages.AuctionEnded) returns (bool) {
        return proxyClaimTokens(msg.sender);
    }

    /// @notice Claim auction tokens for `receiverAddress` after the auction has ended.
    /// @dev Claims tokens for `receiverAddress` after auction has ended.
    /// @param receiverAddress Tokens will be assigned to this address if eligible.
    function proxyClaimTokens(address receiverAddress)
        public
        atStage(Stages.AuctionEnded)
        returns (bool)
    {
        // Waiting period after the end of the auction, before anyone can claim tokens
        // Ensures enough time to check if auction was finalized correctly
        // before users start transacting tokens
        require(now > finalizedTime + TOKEN_CLAIM_WAITING_PERIOD);
        require(receiverAddress != 0x0);

        if (bids[receiverAddress] == 0) {
            return false;
        }

        uint num = (tokenMultiplier * bids[receiverAddress]) / finalPrice;

        // Due to finalPrice floor rounding, the number of assigned tokens may be higher
        // than expected. Therefore, the number of remaining unassigned auction tokens
        // may be smaller than the number of tokens needed for the last claimTokens call
        uint auctionTokensBalance = token.balanceOf(address(this));
        if (num > auctionTokensBalance) {
            num = auctionTokensBalance;
        }

        // Update the total amount of funds for which tokens have been claimed
        fundsClaimed += bids[receiverAddress];

        // Set receiver bid to 0 before assigning tokens
        bids[receiverAddress] = 0;

        require(token.transfer(receiverAddress, num));

        ClaimedTokens(receiverAddress, num);

        // After the last tokens are claimed, we change the auction stage
        // Due to the above logic, rounding errors will not be an issue
        if (fundsClaimed == receivedWei) {
            stage = Stages.TokensDistributed;
            TokensDistributed();
        }

        assert(token.balanceOf(receiverAddress) >= num);
        assert(bids[receiverAddress] == 0);
        return true;
    }

    /// @notice Get the XBET price in WEI during the auction, at the time of
    /// calling this function. Returns `0` if auction has ended.
    /// Returns `startPrice` before auction has started.
    /// @dev Calculates the current XBET token price in WEI.
    /// @return Returns WEI per XBET (tokenMultiplier * Rei).
    function price() public constant returns (uint) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.TokensDistributed) {
            return finalPrice;
        }
        return calcTokenPrice();
    }

    /// @notice Get the missing funds needed to end the auction,
    /// calculated at the current XBET price in WEI.
    /// @dev The missing funds amount necessary to end the auction at the current XBET price in WEI.
    /// @return Returns the missing funds amount in WEI.
    function missingFundsToEndAuction() constant public returns (uint) {

        uint requiredWei = tokensAuctioned * price() / tokenMultiplier;
        if (requiredWei <= receivedWei) {
            return 0;
        }

        return requiredWei - receivedWei;
    }

    /*
     *  Private functions
     */
    /// @dev Calculates the token price (WEI / XBET) at the current timestamp.
    /// For every new block the price decreases with priceDecreaseRate * numberOfNewBLocks
    /// @return current price
    function calcTokenPrice() constant private returns (uint) {
        uint currentPrice;
        if (stage == Stages.AuctionStarted) {
            currentPrice = startPrice - priceDecreaseRate * (block.number - startBlock);
        }else {
            currentPrice = startPrice;
        }

        return currentPrice;
    }
}