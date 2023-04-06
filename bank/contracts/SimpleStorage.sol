pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The isOwner constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public { //指定合约的拥有者
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner); //判定是否调用合约的人是否时合约拥有者
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {//转移合约拥有者
    require(newOwner != address(0));

    owner = newOwner;
  }

}


contract ERC20 {
	function totalSupply() constant public returns (uint supply);
	function balanceOf(address _owner) constant public returns (uint balance);
	function transfer(address _to, uint _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
	function approve(address _spender, uint _value) public returns (bool success);
	function allowance(address _owner, address _spender) constant public returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract bank is ERC20,Ownable{

    string public constant name = "ReaChainCoin";
    string public constant symbol = "RCC";
    uint8 public constant decimals = 18;
    uint256 public totalsupply;
    uint256 public _id;
    uint256 public WAITTIMEUNTILWITHDRAWORTRANSFER;

    mapping(address => uint256) contributionTime;
    struct Content //项目所需资料
    {
        uint256 _id;
        string _introduce;
        address project_party;
        uint256 demand;
        address contract_address;
        bool permissions;
    }
    Content[] public contents;
    address[] public partner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    mapping (address => uint256) public amount;
    mapping (address => bool) public release;
    mapping (address => uint256) public project_address;
    event a(address,uint256);

    modifier isone(){
        require(!release[msg.sender]);
        _;
    }
    function investment() payable {  //投资者投资eth获得代币令牌
        amount[msg.sender] = msg.value;

        balances[msg.sender]=msg.value*1000/10e17;
        totalsupply+=msg.value*1000/10e17;
    }


    function project(string introduce,uint num,address _contract) isone{//项目方申请添加项目

        uint id = contents.push(Content(_id,introduce,msg.sender, num,_contract,false))-1 ;
        project_address[msg.sender] = id;
        release[msg.sender] = true;
        _id++;
    }


    function recognition(uint  id) onlyOwner{//改变申请项目的状态，为true时可以获得投资
        contents[id].permissions=true;
    }

    function withdrawals(){//项目方获取投资资金
       require(contents[project_address[msg.sender]].permissions==true);
       address wd = contents[project_address[msg.sender]].contract_address;
       uint256 num = contents[project_address[msg.sender]].demand;
       a(wd,num);
       wd.transfer(num);
       contents[project_address[msg.sender]].permissions=false;
    }

    function profit() public payable {//盈利接口呀

    }

    function Share_out_bonus(){//投资者通过自己占有的代币比例分红
        uint256 balance =  balances[msg.sender];
        uint256 share_out_bonus = this.balance/balance;//??
        msg.sender.transfer(share_out_bonus);
    }


    function retbal()public view returns(uint256)//查看合约中余额
    {
       return  this.balance;
    }

    function contents_length()public view returns(uint){//项目数量

        return contents.length;
    }

    function totalSupply() constant public returns(uint){//查看代币总数量
        return totalsupply;
    }

   function balanceOf(address _owner) constant public returns(uint){
    return balances[_owner];
   }

 // don't allow transfers before the required wait-time
 // and don't allow transfers to this contract addr, it'll just kill tokens
  function transfer(address _to, uint256 _value) public returns (bool success){
   require(balances[msg.sender] >= _value
   && contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp
   && _to != address(this)
   && _to != address(0));

  // safely subtract
  balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
  balances[_to] = SafeMath.add(balances[_to], _value);

  // log event
  emit Transfer(msg.sender, _to, _value);
  return true;
 }

 // don't allow transfers before the required wait-time
 // and don't allow transfers to the contract addr, it'll just kill tokens
 function transferFrom(address _from, address _to, uint _value) public returns(bool){
  require(allowed[_from][msg.sender] >= _value
   && balances[_from] >= _value
   && contributionTime[_from] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp
   && _to != address(this)
   && _to != address(0));

  // safely add to _to and subtract from _from, and subtract from allowed balances.
  balances[_to] = SafeMath.add(balances[_to], _value);
     balances[_from] = SafeMath.sub(balances[_from], _value);
    allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);

    // log event
  emit Transfer(_from, _to, _value);
  return true;

 }

 function approve(address _spender, uint _value) public returns(bool){

  allowed[msg.sender][_spender] = _value;
  emit Approval(msg.sender, _spender, _value);
  // log event
  return true;
 }

 function allowance(address _owner, address _spender) constant public returns(uint){
  return allowed[_owner][_spender];
 }

}




/**
 * @title SafeMath。//SafeMath合约
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

/**
* @dev Multiplies two numbers, throws on overflow.
*/
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
   return 0;
 }
 uint256 c = a * b;
 assert(c / a == b);
 return c;
}

/**
* @dev Integer division of two numbers, truncating the quotient.
*/
function div(uint256 a, uint256 b) internal pure returns (uint256) {
 // assert(b > 0); // Solidity automatically throws when dividing by 0
 uint256 c = a / b;
 // assert(a == b * c + a % b); // There is no case in which this doesn't hold
 return c;
}

/**
* @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
*/
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 assert(b <= a);
 return a - b;
}

/**
* @dev Adds two numbers, throws on overflow.
*/
function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
}
}
