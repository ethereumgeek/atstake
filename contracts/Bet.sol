pragma solidity 0.4.24;

/**
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BetManager {

    Bet[] public bets;
    mapping(address => uint[]) public betsForAddress;

    constructor() public {
    }

    event EventBetCreated(
        address sender,
        uint betIndex,
        bytes32 hashOfBet,
        string textOfBet
    );

    function createBet(
        bytes32 _hashOfBet,
        string _textOfBet,
        address[] _participants, 
        uint[] _payment,
        uint _arbitrationRequestAllowedAfterTimestamp,
        uint _daysToPayArbitrationFeeAfterArbitrationRequest,
        uint _betCanceledAfterTimestamp) public returns (uint) {
        
        require(_participants.length == 3);
        require(_payment.length == 3);
        require(msg.sender == _participants[0] || msg.sender == _participants[1]);

        Bet bet = new Bet(
            _hashOfBet,
            _participants[0],
            _participants[1],
            _participants[2],
            _payment[0],
            _payment[1],
            _payment[2],
            _arbitrationRequestAllowedAfterTimestamp,
            _daysToPayArbitrationFeeAfterArbitrationRequest,
            _betCanceledAfterTimestamp);
        
        uint betIndex = bets.push(bet) - 1;
        
        betsForAddress[_participants[0]].push(betIndex);

        if(_participants[1] != _participants[0]) {
            betsForAddress[_participants[1]].push(betIndex);
        }

        if(_participants[2] != _participants[0] && _participants[2] != _participants[1]) {
            betsForAddress[_participants[2]].push(betIndex);
        }
        
        emit EventBetCreated(
            msg.sender,
            betIndex,
            _hashOfBet,
            _textOfBet);
        
        return betIndex;
    }
    
    function getBetsForAddress(address _addr) public view returns (uint[]) {
        return betsForAddress[_addr];
    }
}


contract Bet {

    enum ResolutionStatus { None, Person1Wins, Person2Wins, Tie }

    ResolutionStatus public person1Resolution;
    ResolutionStatus public person2Resolution;
    ResolutionStatus public arbiterResolution;
    ResolutionStatus public resolution;
    
    bytes32 public hashOfBet;
    address public person1;
    address public person2;
    address public arbiter;
    uint public person1BetAmount;
    uint public person2BetAmount;
    uint public person1Balance;
    uint public person2Balance;
    uint public arbitrationFee;
    uint public daysToPayArbitrationFeeAfterArbitrationRequest; // how long does other bettor have to respond to arbitration request
    uint public arbitrationRequestAllowedAfterTimestamp; // no one can try to summon the arbiter before this
    uint public arbitrationJudgmentAllowedAfterTimestamp; // arbiter can't render judgment before this 
    uint public betCanceledAfterTimestamp; // timeout after which ppl can get their money back
    bool public arbitrationOccurred;
    bool public defaultJudgmentOccurred;
    bool public person1RequestedArbitration;
    bool public person2RequestedArbitration;
    bool public onlyWithdrawAllowed; // No more action permitted on this bet

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    // Helper function that ensures that whenever we set the resolution, we update balances
    function setResolution( ResolutionStatus _resolution ) internal {
        resolution = _resolution;
        adjustBalancesBasedOnResolution();
    }

    function arbitrationJudgmentAllowed() public view returns (bool) {
        if(!person1RequestedArbitration && !person2RequestedArbitration){
            // If no one has requested it, arbiter can't judge
            return false;
        }
        // We require that both people have paid the arbiter fee, because if one hasn't the other person can just get a default judgment.
        // Then, arbiter can judge if either both bettors requested it, or if they've given the other bettor enough time.
        return (person1Balance == add(person1BetAmount, arbitrationFee)) && (person2Balance == add(person2BetAmount,arbitrationFee)) &&
            ((person1RequestedArbitration && person2RequestedArbitration) || (block.timestamp > arbitrationJudgmentAllowedAfterTimestamp));
    }

    modifier betOpen (){
        require (resolution == ResolutionStatus.None);
        require (betCanceledAfterTimestamp == 0 || block.timestamp <= betCanceledAfterTimestamp);
        require (!onlyWithdrawAllowed);
        _;
    }

    modifier onlyBettors (){
        require(msg.sender == person1 || msg.sender == person2);
        _;
    }

    modifier betLockedIn (){
        require (person1Balance >= person1BetAmount && person2Balance >= person2BetAmount);
        _;
    }
  
    constructor(
        bytes32 _hashOfBet,
        address _person1, 
        address _person2, 
        address _arbiter, 
        uint _person1BetAmount,
        uint _person2BetAmount,
        uint _arbitrationFee,
        uint _arbitrationRequestAllowedAfterTimestamp,
        uint _daysToPayArbitrationFeeAfterArbitrationRequest,
        uint _betCanceledAfterTimestamp
    ) public {        
        person1 = _person1;
        person2 = _person2;
        arbiter = _arbiter;
        hashOfBet = _hashOfBet;
        person1BetAmount = _person1BetAmount;
        person2BetAmount = _person2BetAmount;
        arbitrationFee = _arbitrationFee;
        arbitrationRequestAllowedAfterTimestamp = _arbitrationRequestAllowedAfterTimestamp;
        daysToPayArbitrationFeeAfterArbitrationRequest = _daysToPayArbitrationFeeAfterArbitrationRequest;
        betCanceledAfterTimestamp = _betCanceledAfterTimestamp;
    }


    // Allow any deposit if it brings the total paid up to a 'proper' state.
    function deposit() public payable betOpen() onlyBettors() {
        if (msg.sender == person1) {
            person1Balance += msg.value;
            require(person1Balance == person1BetAmount || person1Balance == add(person1BetAmount, arbitrationFee));
        } else {
            // onlyBettors modifier ensures the other option is person2
            person2Balance += msg.value;
            require(person2Balance == person2BetAmount || person2Balance == add(person2BetAmount, arbitrationFee));
        }
    }

    function withdraw() public onlyBettors(){
        require (onlyWithdrawAllowed || person1Balance < person1BetAmount || person2Balance < person2BetAmount);     

        if(msg.sender == person1 && person1Balance > 0){
            uint amountToWithdraw1 = person1Balance;
            person1Balance = 0;
            person1.transfer(amountToWithdraw1);
        } else if( msg.sender == person2 && person2Balance > 0){
            uint amountToWithdraw2 = person2Balance;
            person2Balance = 0;
            person2.transfer(amountToWithdraw2);
        }

        // If they called this before the bet was locked in, disable the bet.
        onlyWithdrawAllowed = true;
    }
    
    // Default judgment occurs when someone pays for arbitration and their opponent does not, 
    // causing their opponent to lose automatically
    function requestDefaultJudgment() public betOpen() betLockedIn() onlyBettors() {
        require (person1RequestedArbitration || person2RequestedArbitration);
        require (block.timestamp > arbitrationJudgmentAllowedAfterTimestamp);

        // Require exactly one person paid the (nonzero) arbitration fee, and one didn't.
        require (person1Balance > person1BetAmount || person2Balance > person2BetAmount);
        require (person1Balance == person1BetAmount || person2Balance == person2BetAmount);

        // If we pass the require statements, we know a default judgment is justified
        if( person1Balance > person1BetAmount ){
            setResolution(person1Resolution);
        } else{
            setResolution(person2Resolution);
        }

        defaultJudgmentOccurred = true;
    }
        
    // If you haven't already paid for arbitration, you need to pay when requesting arbitration
    function requestArbitration() public payable betOpen() betLockedIn() onlyBettors() {
        require (block.timestamp > arbitrationRequestAllowedAfterTimestamp);
        
        // If someone requests arbitration, make sure they've entered a resolution
        require ((msg.sender == person1 && person1Resolution != ResolutionStatus.None) || 
            (msg.sender == person2 && person2Resolution != ResolutionStatus.None));
        
        if( msg.sender == person1 ){
            person1Balance += msg.value;                
            require (person1Balance == add(person1BetAmount, arbitrationFee));
            person1RequestedArbitration = true;            
        } else {
            // sender must be person2, because we check above that it's one of the two.
            person2Balance += msg.value;                
            require (person2Balance == add(person2BetAmount, arbitrationFee));
            person2RequestedArbitration = true;
        }

        if(arbitrationJudgmentAllowedAfterTimestamp == 0){
            // Only set this the first time arbitration is requested
            arbitrationJudgmentAllowedAfterTimestamp = add(block.timestamp, daysToPayArbitrationFeeAfterArbitrationRequest * (1 days));
        }
    }

    function adjustBalancesBasedOnResolution() internal {
        assert (resolution != ResolutionStatus.None);
        require (!onlyWithdrawAllowed);

        if( resolution == ResolutionStatus.Person1Wins ){
            person1Balance = add(person1Balance, person2BetAmount);
            person2Balance = sub(person2Balance, person2BetAmount);
        } else if( resolution == ResolutionStatus.Person2Wins ){
            person2Balance = add(person2Balance, person1BetAmount);
            person1Balance = sub(person1Balance, person1BetAmount);
        } else{
            // If it was a tie, no adjustment needed
        }

        if (arbitrationOccurred) {
            // The arbitor was already paid.. We need to figure out whose balance to deduct
            if( person1Resolution == arbiterResolution ){
                person2Balance = sub(person2Balance, arbitrationFee);
            } else if( person2Resolution == arbiterResolution ) {
                person1Balance = sub(person1Balance, arbitrationFee);
            } else{
                // Neither person agreed with the arbiter -- both split the cost
                person1Balance = sub(person1Balance, arbitrationFee/2);
                person2Balance = sub(person2Balance, arbitrationFee/2);
            }
        }

        onlyWithdrawAllowed = true;
    }
    
    function resolve(ResolutionStatus _resolution) public betOpen() betLockedIn() {
        require (msg.sender == person1 || msg.sender == person2 || msg.sender == arbiter);
        // If the resolver is the arbiter, make sure they're allowed to render a judgment.
        require ((msg.sender != arbiter) || arbitrationJudgmentAllowed());         
        
        if (msg.sender == person1) {
            person1Resolution = _resolution;
        } else if (msg.sender == person2) {
            person2Resolution = _resolution;
        } else if (msg.sender == arbiter) {
            arbiterResolution = _resolution;
        }
        
        if (person1Resolution == person2Resolution && person1Resolution != ResolutionStatus.None) {
            setResolution(person1Resolution);
        } else if (arbiterResolution != ResolutionStatus.None) {
            // If the bettors haven't been able to agree, go with the arbiter resolution.
            // We might want to revisit this rule later (don't let arbiter pick a result that no one else picked)    
            setResolution(arbiterResolution);
            arbitrationOccurred = true;
            if(arbitrationFee > 0 ){
                // It's safe to assume this won't fail, because if the arbiter is malicious they could just not arbitrate.
                arbiter.transfer(arbitrationFee);
            }
        }
    }

    // If someone accidentally sent ERC20 tokens to this contract, 
    // allow one of the other participants to send them back.
    // Rely on the sender to ensure the balance is >= value since we want to keep this function simple.
    function sendERC20Tokens(address tokenContract, address receiver, uint256 value) public {
        require (msg.sender == person1 || msg.sender == person2 || msg.sender == arbiter);
        require (receiver != msg.sender);
        require (receiver == person1 || receiver == person2);

        ERC20Basic(tokenContract).transfer(receiver, value);
    }
}