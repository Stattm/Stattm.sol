pragma solidity ^0.4.17;
import './Ownable.sol';
import './Crowdsale.sol';
import './MintableToken.sol';
import './BurnableToken.sol';
import './KycContract.sol';
import './SafeMath.sol';



contract StattmCrowdsale is Ownable, Crowdsale, MintableToken, BurnableToken, KycContract {
    using SafeMath for uint256;

    // TODO : Update the Time
    // 2018-08-25 00:00:00 GMT - start time for pre sale
    uint256 private constant presaleStartTime = 1535223482;

    // 2018-10-5 23:59:59 GMT - end time for pre sale
    uint256 private constant presaleEndTime = 1538765882;

    // 2019-1-15 00:00:00 GMT - start time for main sale
    uint256 private constant itosaleStartTime = 1547578682;

    // 2019-2-28 00:00:00 GMT - start time for main sale
    uint256 private constant itosaleEndTime = 1551380282;

    // 2019-3-28 00:00:00 GMT - start time for main sale
    uint256 private constant mainsaleStartTime = 1553799482;

    // 2019-5-11 23:59:59 GMT - end time for main sale
    uint256 private constant mainsaleEndTime = 1557601082;


    // ===== Cap & Goal Management =====
    /* Pre-ICO | Soft cap : 166 ETH , Hard cap : 666 ETH
       ITO     | soft cap : 1600 ETH , hard cap : 4000 ETH
       ICO     | soft cap : 4250 ETH , hard cap : 10000 ETH
    */
    uint256 public constant presaleCap = 166 * (10 ** uint256(decimals));
    uint256 public constant itosaleCap = 1600 * (10 ** uint256(decimals));
    uint256 public constant mainsaleCap = 4250 * (10 ** uint256(decimals));
    uint256 public constant presaleGoal = 666 * (10 ** uint256(decimals));
    uint256 public constant itosaleGoal = 4000 * (10 ** uint256(decimals));
    uint256 public constant mainsaleGoal = 10000 * (10 ** uint256(decimals));

    // i will do changes at my end and will join you again in monring

    // ============= Token Distribution ================ some mistakes
    uint256 public constant INITIAL_SUPPLY = 100100100 * (10 ** uint256(decimals));
    uint256 public constant totalTokensForSale = 65000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForTeam = 9100100 * (10 ** uint256(decimals));
    uint256 public constant tokensForReserve = 12000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForBounty = 2000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForPartnerGift = 1000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForAdvisors = 11000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForDevelopmentTeam = 1000000 * (10 ** uint256(decimals));

    // how many token units a buyer gets per wei
    uint256 public rate;
    mapping (address => uint256) public deposited;
    mapping (address => uint256) public preico_deposited;
    mapping (address => uint256) public ito_deposited;
    mapping (address => uint256) public mainsale_deposited;
    
    address[] public preico_investers;
    address[] public ito_investers;
    address[] public mainsale_investers;


    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Finalized();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function StattmCrowdsale(
      address _owner,
      address _wallet
      ) public Crowdsale(_wallet) {

        require(_wallet != address(0));
        require(_owner != address(0));
        owner = _owner;
        transfersEnabled = true;
        mintingFinished = false;
        totalSupply = INITIAL_SUPPLY;
        rate = 6000;
        bool resultMintForOwner = mintForOwner(owner);
        require(resultMintForOwner);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _investor) public  payable returns (uint256){
        require(_investor != address(0));
        require(verifiedAddresses[msg.sender]);
        require(validPurchase());
        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount);
        if (tokens == 0) {revert();}

        // update state
        if (isPresalePeriod()) {
          PresaleWeiRaised = PresaleWeiRaised.add(weiAmount);
          preico_deposited[msg.sender] = msg.value;
          if (preico_deposited[msg.sender] == 0){
              preico_investers.push(msg.sender);
          }
        } else if (isItosalePeriod()) {
          ItosaleWeiRaised = ItosaleWeiRaised.add(weiAmount);
          ito_deposited[msg.sender] = msg.value;
          if (ito_deposited[msg.sender] == 0){
              ito_investers.push(msg.sender);
          }
        }else if (isMainsalePeriod()) {
          mainsaleWeiRaised = mainsaleWeiRaised.add(weiAmount);
          mainsale_deposited[msg.sender] = msg.value;
          if (mainsale_deposited[msg.sender] == 0){
              mainsale_investers.push(msg.sender);
          }
        }
        tokenAllocated = tokenAllocated.add(tokens);
        mint(_investor, tokens, owner);

        emit TokenPurchase(_investor, weiAmount, tokens);
        if (deposited[_investor] == 0) {
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
      return _weiAmount.mul(rate);
    }

    // ====================== Price Management =================
    function setPrice() public onlyOwner {
      if (isPresalePeriod()) {
        rate = 6000;
      } else if (isMainsalePeriod()) {
        rate = _itoratecalculation();
      } else if (isMainsalePeriod()) {
        rate = _mainsaleratecalculation();
      }
    }
    
    function _itoratecalculation() private view returns(uint _rate) {
         if (now <= (itosaleStartTime + 10 days)) {
             _rate = 6000;
         }else if (now <= (itosaleStartTime + 20 days)) {
             _rate = 5454;
         }else if (now <= (itosaleStartTime + 30 days)) {
             _rate = 5000;
         }else if (now <= (itosaleStartTime + 40 days)) {
             _rate = 4615;
         }else {
             _rate = 4285;
         }
    }
    
    function _mainsaleratecalculation() private view returns(uint _rate) {
        if (now <= (mainsaleStartTime + 10 days)) {
             _rate = 4000;
         }else if (now <= (mainsaleStartTime + 20 days)) {
             _rate = 3529;
         }else if (now <= (mainsaleStartTime + 30 days)) {
             _rate = 3157;
         }else if (now <= (mainsaleStartTime + 40 days)) {
             _rate = 2857;
         }else {
             _rate = 2400;
         }
        
    }
    
    function isPresalePeriod() public view returns (bool) {
      if (now >= presaleStartTime && now < presaleEndTime) {
        return true;
      }
      return false;
    }
    
    function isItosalePeriod() public view returns (bool) {
      if (now >= itosaleStartTime && now < itosaleEndTime) {
        return true;
      }
      return false;
    }

    function isMainsalePeriod() public view returns (bool) {
      if (now >= mainsaleStartTime && now < mainsaleEndTime) {
        return true;
      }
      return false;
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForOwner(address _wallet) internal returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[_wallet] = balances[_wallet].add(INITIAL_SUPPLY);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
      bool withinCap =  true;
      if (isPresalePeriod()) {
        withinCap = PresaleWeiRaised.add(msg.value) <= presaleCap;
      } else if (isItosalePeriod()) {
        withinCap = ItosaleWeiRaised.add(msg.value) <= itosaleCap;
      }else if (isMainsalePeriod()) {
          withinCap = mainsaleWeiRaised.add(msg.value) <= mainsaleCap;
      }
      bool withinPeriod = isPresalePeriod() || isItosalePeriod() || isMainsalePeriod();
      bool minimumContribution = msg.value >= 0.5 ether;
      return withinPeriod && minimumContribution && withinCap;
    }
    
    function tokenBurn() private onlyOwner {
      require(!goalReached());
      if (now <= presaleEndTime && now <= itosaleStartTime){
          for (uint cnt = 0; cnt < preico_investers.length; cnt++) {
            address investor = preico_investers[cnt];
            investor.transfer(preico_deposited[investor]);
            emit Refunded(investor, preico_deposited[investor]);
            
          }
      }
      if (now <= itosaleEndTime && now <= mainsaleStartTime){
          unsold = itosaleCap.sub(ItosaleWeiRaised);
          burn(unsold);
          for (cnt = 0; cnt < ito_investers.length; cnt++) {
            investor = ito_investers[cnt];
            investor.transfer(ito_deposited[investor]);
            emit Refunded(investor, ito_deposited[investor]);
            
          }
      }
      if (now >= mainsaleEndTime){
          unsold = mainsaleCap.sub(mainsaleWeiRaised);
          burn(unsold);
          for (cnt = 0; cnt < mainsale_investers.length; cnt++) {
            investor = mainsale_investers[cnt];
            investor.transfer(mainsale_deposited[investor]);
            emit Refunded(investor, mainsale_deposited[investor]);
            
          }
      }
    }
    
    
    function goalReached() public view returns (bool) {
      if (isPresalePeriod()) {
        return PresaleWeiRaised >= presaleCap;
      }else if (isItosalePeriod()) {
        return ItosaleWeiRaised >= itosaleCap;
      }else if (isMainsalePeriod()){
        return mainsaleWeiRaised >= mainsaleCap;
      }
    }

    function readyForFinish() internal view returns(bool) {
      bool endPeriod = now < mainsaleEndTime;
      bool reachCap = tokenAllocated <= mainsaleCap;
      return endPeriod || reachCap;
    }

    // Finish: Mint Extra Tokens as needed before finalizing the Crowdsale.
    function finalize(
      address _teamFund,
      address _reserveFund,
      address _bountyFund,
      address _partnersGiftFund,
      address _advisorFund,
      address _developmentFund
      ) public onlyOwner returns (bool result) {
        require(_teamFund != address(0));
        require(_reserveFund != address(0));
        require(_bountyFund != address(0));
        require(_partnersGiftFund != address(0));
        require(_advisorFund != address(0));
        require(_developmentFund != address(0));
        require(readyForFinish());
        result = false;
        uint256 unsoldTokens = totalTokensForSale - tokenAllocated;
        burn(unsoldTokens);
        mint(_teamFund, tokensForTeam, owner);
        mint(_reserveFund, tokensForReserve, owner);
        mint(_bountyFund, tokensForBounty, owner);
        mint(_partnersGiftFund, tokensForPartnerGift, owner);
        mint(_advisorFund, tokensForAdvisors, owner);
        mint(_developmentFund, tokensForDevelopmentTeam, owner);
        address contractBalance = this;
        wallet.transfer(contractBalance.balance);
        finishMinting();
        emit Finalized();
        result = true;
    }

}
