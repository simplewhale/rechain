{\rtf1\ansi\ansicpg936\cocoartf1504\cocoasubrtf830
{\fonttbl\f0\fnil\fcharset134 PingFangSC-Regular;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
{\info
{\author alen}}\vieww16740\viewh14980\viewkind1
\deftab720
\pard\pardeftab720\ri0\partightenfactor0

\f0\fs28 \cf0 pragma solidity^0.4.21;\
\
\
\
contract InvestmentProjectsInterface \{\
\
	function receiveEtherFromBank() payable public;\
\
\}\
\
contract bankrollInterface \{\
	function giveEtherToTreasureHunt(uint256 amount) public;\
	function receiveEtherFromProjects() payable public;\
	function getDivided() public view returns(uint256);\
	function receiveUserFromProjects(address user) public;\
\
\}\
\
contract ERC20 \{\
	function totalSupply() constant public returns (uint supply);\
	function balanceOf(address _owner) constant public returns (uint balance);\
	function transfer(address _to, uint _value) public returns (bool success);\
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);\
	function approve(address _spender, uint _value) public returns (bool success);\
	function allowance(address _owner, address _spender) constant public returns (uint remaining);\
	event Transfer(address indexed _from, address indexed _to, uint _value);\
	event Approval(address indexed _owner, address indexed _spender, uint _value);\
\}\
\
contract bankroll is ERC20, bankrollInterface\{\
    using SafeMath for *;\
\
    address owner;\
    uint256 public MAXIMUMINVESTMENTSALLOWED;\
	uint256 public WAITTIMEUNTILWITHDRAWORTRANSFER;\
	uint256 public DEVELOPERSFUND;\
	uint256 public INVESTMENTFUNDS;\
	//address of contract TreasureHunt\
	address public TREASUREHUNT;\
	address[] public users;\
	uint public LOTTERYTOKENS;\
	uint16 public RewardPoints = 1000;\
\
	mapping(address => bool) public TRUSTEDADDRESSES;\
\
	// mapping to log the last time a user contributed to the bankroll\
	mapping(address => uint256) contributionTime;\
\
	// constants for ERC20 standard\
	string public constant name = "ReaChainCoin";\
	string public constant symbol = "RCC";\
	uint8 public constant decimals = 18;\
	// variable total supply\
	uint256 public totalSupply;\
\
	// mapping to store tokens\
	mapping(address => uint256) public balances;\
	mapping(address => mapping(address => uint256)) public allowed;\
\
\
    event FundBankroll(address contributor, uint256 etherContributed, uint256 tokensReceived);\
	event CashOut(address contributor, uint256 etherWithdrawn, uint256 tokensCashedIn);\
	event FailedSend(address sendTo, uint256 amt);\
    event Reward(address useradr , uint256 reward);\
\
    // checks that an address is a "trusted address of a legitimate EOSBet game"\
	modifier addressInTrustedAddresses(address thisAddress)\{\
\
		require(TRUSTEDADDRESSES[thisAddress]);\
		_;\
	\}\
\
    function bankroll(address treasureHunt)  public payable\{\
        require (msg.value > 0);\
        owner = msg.sender;\
\
        // 100 tokens/ether is the inital seed amount, so:\
		uint256 initialTokens = msg.value * 100;\
		balances[msg.sender] = initialTokens;\
		totalSupply = initialTokens;\
\
		// log a mint tokens event\
		emit Transfer(0x0, msg.sender, initialTokens);\
\
		WAITTIMEUNTILWITHDRAWORTRANSFER = 24 hours;\
		MAXIMUMINVESTMENTSALLOWED = 1000 ether;\
\
		// insert given game addresses into the TRUSTEDADDRESSES mapping, and save the addresses as global variables\
		TRUSTEDADDRESSES[treasureHunt] = true;\
\
		TREASUREHUNT = treasureHunt;\
    \}\
\
    ///////////////////////////////////////////////\
	// VIEW FUNCTIONS\
	///////////////////////////////////////////////\
\
	function checkWhenContributorCanTransferOrWithdraw(address _Address) view public returns(uint256)\{\
		return contributionTime[_Address];\
	\}\
\
	function getDivided() view public returns(uint256)\{\
\
		uint256 rewardValue = SafeMath.sub(SafeMath.sub(address(this).balance, DEVELOPERSFUND),INVESTMENTFUNDS);\
		// returns the total balance minus the developers fund, as the amount of active bankroll\
		return  rewardValue * RewardPoints / 1000;\
	\}\
\
	///////////////////////////////////////////////\
	// BANKROLL CONTRACT <-> GAME CONTRACTS functions\
	///////////////////////////////////////////////\
\
	function receiveEtherFromProjects() payable public addressInTrustedAddresses(msg.sender)\{\
		// this function will get called from the game contracts when someone starts a game.\
	\}\
\
	function giveEtherToTreasureHunt(uint256 amount) addressInTrustedAddresses(msg.sender) public\{\
        require(amount <= INVESTMENTFUNDS);\
        INVESTMENTFUNDS = INVESTMENTFUNDS - amount;\
        InvestmentProjectsInterface(TREASUREHUNT).receiveEtherFromBank.value(amount)();\
    \}\
\
	function receiveUserFromProjects(address user) addressInTrustedAddresses(msg.sender) public\{\
	    users.push(user);\
	\}\
	///////////////////////////////////////////////\
	// BANKROLL CONTRACT MAIN FUNCTIONS\
	///////////////////////////////////////////////\
\
	function investment() public payable \{\
\
		// save in memory for cheap access.\
		// this represents the total bankroll balance before the function was called.\
		uint256 currentTotalBankroll = SafeMath.sub(getDivided(), msg.value);\
		uint256 maxInvestmentsAllowed = MAXIMUMINVESTMENTSALLOWED;\
\
		require(currentTotalBankroll < maxInvestmentsAllowed && msg.value != 0);\
\
		uint256 currentSupplyOfTokens = totalSupply;\
		uint256 contributedEther;\
\
        //Whether the ether of investment is excessive.\
		bool contributionTakesBankrollOverLimit;\
		//If the investment is too much, the rest will return.\
		uint256 ifContributionTakesBankrollOverLimit_Refund;\
\
		uint256 creditedTokens;\
\
		if (SafeMath.add(currentTotalBankroll, msg.value) > maxInvestmentsAllowed)\{\
			// allow the bankroller to contribute up to the allowed amount of ether, and refund the rest.\
			contributionTakesBankrollOverLimit = true;\
			// set contributed ether as (MAXIMUMINVESTMENTSALLOWED - BANKROLL)\
			contributedEther = SafeMath.sub(maxInvestmentsAllowed, currentTotalBankroll);\
			// refund the rest of the ether, which is (original amount sent - (maximum amount allowed - bankroll))\
			ifContributionTakesBankrollOverLimit_Refund = SafeMath.sub(msg.value, contributedEther);\
\
		\}\
		else \{\
			contributedEther = msg.value;\
\
		\}\
\
		if (currentSupplyOfTokens != 0)\{\
			// determine the ratio of contribution versus total BANKROLL.\
			creditedTokens = SafeMath.mul(contributedEther, currentSupplyOfTokens) / currentTotalBankroll;\
		\}\
		else \{\
			// edge case where ALL money was cashed out from bankroll\
			// so currentSupplyOfTokens == 0\
			// currentTotalBankroll can == 0 or not, if someone mines/selfdestruct's to the contract\
			// but either way, give all the bankroll to person who deposits ether\
			creditedTokens = SafeMath.mul(contributedEther, 100);\
		\}\
\
		// now update the total supply of tokens and bankroll amount\
		totalSupply = SafeMath.add(currentSupplyOfTokens, creditedTokens);\
\
		// now credit the user with his amount of contributed tokens\
		balances[msg.sender] = SafeMath.add(balances[msg.sender], creditedTokens);\
\
		// update his contribution time for stake time locking\
		contributionTime[msg.sender] = block.timestamp;\
\
		// now look if the attempted contribution would have taken the BANKROLL over the limit,\
		// and if true, refund the excess ether.\
		if (contributionTakesBankrollOverLimit)\{\
			msg.sender.transfer(ifContributionTakesBankrollOverLimit_Refund);\
		\}\
\
        INVESTMENTFUNDS = SafeMath.add(INVESTMENTFUNDS,contributedEther * 20 / 100);\
\
		// log an event about funding bankroll\
		emit FundBankroll(msg.sender, contributedEther, creditedTokens);\
\
		// log a mint tokens event\
		emit Transfer(0x0, msg.sender, creditedTokens);\
	\}\
\
	function cashoutStakeTokens(uint256 _amountTokens) public \{\
		// In effect, this function is the OPPOSITE of the un-named payable function above^^^\
		// this allows bankrollers to "cash out" at any time, and receive the ether that they contributed, PLUS\
		// a proportion of any ether that was earned by the smart contact when their ether was "staking", However\
		// this works in reverse as well. Any net losses of the smart contract will be absorbed by the player in like manner.\
		// Of course, due to the constant house edge, a bankroller that leaves their ether in the contract long enough\
		// is effectively guaranteed to withdraw more ether than they originally "staked"\
\
		// save in memory for cheap access.\
		uint256 tokenBalance = balances[msg.sender];\
		// verify that the contributor has enough tokens to cash out this many, and has waited the required time.\
		require(_amountTokens <= tokenBalance\
			&& contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp\
			&& _amountTokens > 0);\
\
		// save in memory for cheap access.\
		// again, represents the total balance of the contract before the function was called.\
		uint256 currentTotalBankroll = getDivided();\
		uint256 currentSupplyOfTokens = totalSupply;\
\
		// calculate the token withdraw ratio based on current supply\
		uint256 withdrawEther = SafeMath.mul(_amountTokens, currentTotalBankroll) / currentSupplyOfTokens;\
\
		// developers take 1% of withdrawls\
		uint256 developersCut = withdrawEther / 100;\
		uint256 contributorAmount = SafeMath.sub(withdrawEther, developersCut);\
\
		// now update the total supply of tokens by subtracting the tokens that are being "cashed in"\
		totalSupply = SafeMath.sub(currentSupplyOfTokens, _amountTokens);\
\
		// and update the users supply of tokens\
		balances[msg.sender] = SafeMath.sub(tokenBalance, _amountTokens);\
\
		// update the developers fund based on this calculated amount\
		DEVELOPERSFUND = SafeMath.add(DEVELOPERSFUND, developersCut);\
\
		// lastly, transfer the ether back to the bankroller. Thanks for your contribution!\
		msg.sender.transfer(contributorAmount);\
\
		// log an event about cashout\
		emit CashOut(msg.sender, contributorAmount, _amountTokens);\
\
		// log a destroy tokens event\
		emit Transfer(msg.sender, 0x0, _amountTokens);\
	\}\
\
	// TO CALL THIS FUNCTION EASILY, SEND A 0 ETHER TRANSACTION TO THIS CONTRACT WITH EXTRA DATA: 0x7a09588b\
	function cashoutStakeTokens_ALL() public \{\
\
		// just forward to cashoutEOSBetStakeTokens with input as the senders entire balance\
		cashoutStakeTokens(balances[msg.sender]);\
	\}\
\
	///////////////////////////////////////////////\
	// OWNER FUNCTIONS\
	///////////////////////////////////////////////\
    function transferOwnership(address newOwner) public \{\
		require(msg.sender == owner);\
\
		owner = newOwner;\
	\}\
\
    function setRewardPoints(uint16 point) public\{\
        require(msg.sender == owner);\
        require(point >= 0 && point <= 1000);\
\
        RewardPoints = point;\
    \}\
\
    function changeWaitTimeUntilWithdrawOrTransfer(uint256 waitTime) public \{\
		// waitTime MUST be less than or equal to 10 weeks\
		require (msg.sender == owner && waitTime <= 6048000);\
\
		WAITTIMEUNTILWITHDRAWORTRANSFER = waitTime;\
	\}\
\
    function changeMaximumInvestmentsAllowed(uint256 maxAmount) public \{\
		require(msg.sender == owner);\
\
		MAXIMUMINVESTMENTSALLOWED = maxAmount;\
	\}\
\
    function withdrawReward() public\{\
        require(msg.sender == owner);\
\
        uint256 rewardValue = SafeMath.sub(SafeMath.sub(address(this).balance, DEVELOPERSFUND),INVESTMENTFUNDS);\
\
        owner.transfer(rewardValue * ( 1 - RewardPoints / 1000));\
    \}\
\
    function withdrawDevelopersFund(address receiver) public \{\
		require(msg.sender == owner);\
\
\
		// now send the developers fund from the main contract.\
		uint256 developersFund = DEVELOPERSFUND;\
\
		// set developers fund to zero\
		DEVELOPERSFUND = 0;\
\
		// transfer this amount to the owner!\
		receiver.transfer(developersFund);\
	\}\
\
	// rescue tokens inadvertently sent to the contract address\
	function ERC20Rescue(address tokenAddress, uint256 amtTokens) public \{\
		require (msg.sender == owner);\
\
		ERC20(tokenAddress).transfer(msg.sender, amtTokens);\
	\}\
\
	///////////////////////////////\
	// BASIC ERC20 TOKEN OPERATIONS\
	///////////////////////////////\
   function totalSupply() constant public returns(uint)\{\
		return totalSupply;\
	\}\
\
	function balanceOf(address _owner) constant public returns(uint)\{\
		return balances[_owner];\
	\}\
\
	// don't allow transfers before the required wait-time\
	// and don't allow transfers to this contract addr, it'll just kill tokens\
	function transfer(address _to, uint256 _value) public returns (bool success)\{\
		require(balances[msg.sender] >= _value\
			&& contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp\
			&& _to != address(this)\
			&& _to != address(0));\
\
		// safely subtract\
		balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);\
		balances[_to] = SafeMath.add(balances[_to], _value);\
\
		// log event\
		emit Transfer(msg.sender, _to, _value);\
		return true;\
	\}\
\
	// don't allow transfers before the required wait-time\
	// and don't allow transfers to the contract addr, it'll just kill tokens\
	function transferFrom(address _from, address _to, uint _value) public returns(bool)\{\
		require(allowed[_from][msg.sender] >= _value\
			&& balances[_from] >= _value\
			&& contributionTime[_from] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp\
			&& _to != address(this)\
			&& _to != address(0));\
\
		// safely add to _to and subtract from _from, and subtract from allowed balances.\
		balances[_to] = SafeMath.add(balances[_to], _value);\
   		balances[_from] = SafeMath.sub(balances[_from], _value);\
  		allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);\
\
  		// log event\
		emit Transfer(_from, _to, _value);\
		return true;\
\
	\}\
\
	function approve(address _spender, uint _value) public returns(bool)\{\
\
		allowed[msg.sender][_spender] = _value;\
		emit Approval(msg.sender, _spender, _value);\
		// log event\
		return true;\
	\}\
\
	function allowance(address _owner, address _spender) constant public returns(uint)\{\
		return allowed[_owner][_spender];\
	\}\
\
	//Lucky draw\
	function draw(uint lotterytokens) public \{\
	    require(msg.sender == owner);\
	    require(lotterytokens + LOTTERYTOKENS <= totalSupply * 5 /100);\
	    uint len = users.length;\
	    uint num;\
	    if(len < 10)\{\
	      num = 1;\
	    \}else\{\
	      num = len / 10;\
	    \}\
	    uint reward = SafeMath.div(lotterytokens, num);\
	    for(uint i = 0;i <  num;i++)\{\
	        uint index = rand(users.length);\
	        address drawer = users[index];\
	        deleteStrAt(index);\
	        balances[drawer] = SafeMath.add(balances[drawer], reward);\
	        emit Reward(drawer,reward);\
	    \}\
	    LOTTERYTOKENS = SafeMath.add(LOTTERYTOKENS,lotterytokens);\
	    delete users;\
        users.length = 0;\
	\}\
\
	function rand(uint256 len) private  view returns(uint256) \{\
        uint256 random = uint256(keccak256(block.difficulty,now));\
        return  random % len;\
    \}\
\
    function deleteStrAt(uint index) private\{\
       uint len = users.length;\
       if (index >= len) return;\
       for (uint i = index; i<len-1; i++) \{\
         users[i] = users[i+1];\
       \}\
\
       delete users[len-1];\
       users.length.sub(1);\
  \}\
\}\
\
\
pragma solidity ^0.4.18;\
\
library SafeMath \{\
\
  /**\
  * @dev Multiplies two numbers, throws on overflow.\
  */\
  function mul(uint256 a, uint256 b) internal pure returns (uint256) \{\
    if (a == 0) \{\
      return 0;\
    \}\
    uint256 c = a * b;\
    assert(c / a == b);\
    return c;\
  \}\
\
  /**\
  * @dev Integer division of two numbers, truncating the quotient.\
  */\
  function div(uint256 a, uint256 b) internal pure returns (uint256) \{\
    // assert(b > 0); // Solidity automatically throws when dividing by 0\
    uint256 c = a / b;\
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold\
    return c;\
  \}\
\
  /**\
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).\
  */\
  function sub(uint256 a, uint256 b) internal pure returns (uint256) \{\
    assert(b <= a);\
    return a - b;\
  \}\
\
  /**\
  * @dev Adds two numbers, throws on overflow.\
  */\
  function add(uint256 a, uint256 b) internal pure returns (uint256) \{\
    uint256 c = a + b;\
    assert(c >= a);\
    return c;\
  \}\
\}\
\
\
\
contract TreasureHunt is InvestmentProjectsInterface\{\
\
    using SafeMath for *;\
\
    struct treasure\{\
        address Treasure_people;\
        uint id;\
        string area;\
        uint position;\
        uint treasuretime;\
        uint duringtime;\
        uint bonus;\
        bool have;\
        string information;\
    \}\
\
    address public owner;\
\
   // bankroller address\
	address public BANKROLLER;\
\
    treasure[] public treasures;\
\
    mapping(string =>mapping(uint => uint)) indexs;\
\
\
	event Addtreasure(address indexed reaaddress);\
    event Opentreasure(address indexed reaaddress,uint indexed bonus,string indexed information) ;\
\
    modifier ishave(string _area,uint _position)\{\
        require(treasures[indexs[_area][_position]].have);\
        _;\
    \}\
\
\
\
   function  TreasureHunt()  public \{\
       owner = msg.sender;\
       treasures.push(treasure(owner,treasures.length, "A",0,block.timestamp ,0,0,false,"welcome to get treasure!"));\
\
\
  \}\
\
  function receiveEtherFromBank() payable public \{\
		require(msg.sender == BANKROLLER);\
	\}\
\
  // WARNING!!!!! Can only set this function once!\
	function setBankrollerContractOnce(address bankrollAddress) public \{\
		// require that BANKROLLER address == 0x0 (address not set yet), and coming from owner.\
		require(msg.sender == owner && BANKROLLER == address(0));\
\
		// check here to make sure that the bankroll contract is legitimate\
		// just make sure that calling the bankroll contract getBankroll() returns non-zero\
\
		require(bankrollInterface(bankrollAddress).getDivided() != 0);\
\
		BANKROLLER = bankrollAddress;\
	\}\
\
  function addtreasure(string _information , uint _duringtime,string _area,uint _position) payable external  \{\
        require(getstate(_area,_position) == false);\
        uint  id = treasures.length;\
        treasures.push(treasure(msg.sender,id, _area, _position ,  block.timestamp ,_duringtime,msg.value,true,_information));\
        indexs[_area][_position] = id;\
        bankrollInterface(BANKROLLER).receiveUserFromProjects(msg.sender);\
        emit Addtreasure(msg.sender);\
  \}\
\
\
  function getlength() public view returns(uint)\
  \{\
    return    treasures.length;\
  \}\
\
 function isselftreasure(string _area,uint _position) external view returns(address Treasure_people)\{\
       uint  id = indexs[_area][_position];\
       Treasure_people = treasures[id].Treasure_people;\
 \}\
\
\
  function opentreasure(string _area,uint _position) external payable ishave(_area,_position) returns(string,uint)\{\
\
        require(msg.value >= 0.001 ether);\
        uint  id = indexs[_area][_position];\
        require(treasures[id].have == true);\
        require(treasures[id].Treasure_people != msg.sender);\
\
        treasures[id].have=false;\
        bankrollInterface(BANKROLLER).receiveEtherFromProjects.value(msg.value * 80 /100)();\
        bankrollInterface(BANKROLLER).receiveUserFromProjects(msg.sender);\
        owner.transfer(msg.value * 20 /100);\
        msg.sender.transfer(treasures[id].bonus);\
        //emit Opentreasure(treasures[id].Treasure_people,treasures[id].bonus,treasures[id].information);\
        return( treasures[id].information,treasures[id].bonus);\
\
\
  \}\
\
  function getstate(string _area,uint _position) public view returns(bool)\{\
        uint  id = indexs[_area][_position];\
        return treasures[id].have;\
  \}\
\
  function getbonus(string _area,uint _position) public view ishave(_area,_position) returns(bool)\{\
        uint  id = indexs[_area][_position];\
        if((treasures[id].duringtime.add(treasures[id].treasuretime)) > block.timestamp)\{\
           return false;\
        \}\
        return true;\
  \}\
\
  function getbackhonus(string _area,uint _position) external \{\
\
       uint  id = indexs[_area][_position];\
       require(treasures[id].have == true);\
       require(treasures[id].Treasure_people == msg.sender);\
\
       if((treasures[id].bonus.add(treasures[id].treasuretime)) > 30 * 24 * 60 * 60)\{\
          treasures[id].have = false;\
\
          msg.sender.transfer(treasures[id].bonus);\
        \}\
\
   \}\
\
	///////////////////////////////////////////////\
	// OWNER FUNCTIONS\
	///////////////////////////////////////////////\
	//owner\
	function giveTreasure(string _information , uint _duringtime,string _area,uint _position,uint _reward) public\{\
	    require(msg.sender == owner);\
	    require(getstate(_area,_position) == false);\
\
	    bankrollInterface(BANKROLLER).giveEtherToTreasureHunt(_reward);\
	    uint  id = treasures.length;\
        treasures.push(treasure(msg.sender,id,_area,_position, block.timestamp ,_duringtime,_reward,true,_information));\
        indexs[_area][_position] = id;\
\
	\}\
\
    function transferOwnership(address newOwner) public \{\
		require(msg.sender == owner);\
\
		owner = newOwner;\
	\}\
\
	function ()payable public\{\}\
 \}\
}