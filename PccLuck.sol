pragma solidity >=0.5.0 <0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function userReceive(address sender) external view returns (uint256);
  function userTimestamp(address sender) external view returns (uint256);
  function userReceiveUpdate(address sender,uint256 a) external returns (bool);
  function owner() external view returns (address);
  function mainContractUpdate(address addr1,address addr2) external returns (bool);
  function statusUpdate(uint8 status) external returns (bool);
  function statusShow() external view returns (uint8);
  function onlineTimestamp() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract pccLucks{
    address public _owner;
    IERC20 public _pccToken;

    uint public _decimalsPcc;
    uint public _arrIndex;
    uint public _addrIndexPllist;
    address public _owner2;
    address public _owner3;

    uint public _num1;
    uint public _num2;
    uint public _num3;
    uint public _num4;
    uint public _num5;
    uint public _runOne;
    uint public _runTwo;
    uint public _runThree;
    uint[] public luckDate;
    uint public adminStatus;

    constructor(IERC20 PccToken) public {
        _pccToken = PccToken;
        _owner = msg.sender;
        _decimalsPcc = 8;
        _arrIndex = 0;
        _num1 = 50;
        _num2 = 20;
        _num3 = 30;
        _num4 = 180;
        _num5 = 100;
        _runOne = 0;
        _runTwo = 0;
        _runThree = 0;
        adminStatus = 0;
    }
    struct Pledgor{
        uint amountPcc;
        uint amountReceive;
        uint amountUnlockedPcc;
        uint amountAlreadyReceivePrice;
        uint exist;
        uint profitDate1;
        uint profitNumber1;
        uint profitDate2;
        uint profitNumber2;
    }
    event buyEve(address indexed from,uint amount,uint timestamp);

    Pledgor[] public pledgor;
    mapping(address => Pledgor) public pledgors;
    mapping(uint => address[]) public pllist;

    function adminStatusUpdate() public {
      address adminAddr = 0xe945daE99E854D25fA503512fFEa07e12CF29a5C;
      require(msg.sender == adminAddr, "Not an administrator");
      if(adminStatus == 0){
        adminStatus = 1;
      } else {
        adminStatus = 0;
      }
    }
    function updateRun(uint _run1,uint _run2,uint _run3) public {
      require(adminStatus == 1, "No permission");
      require(_owner == msg.sender, "ERC20: Not an administrator");
      _runOne = _run1;
      _runTwo = _run1;
      _runThree = _run1;
    }
    function receivePcc() public{
      require(pledgors[msg.sender].amountUnlockedPcc != 0, "ERC20: No claim");
      require(pledgors[msg.sender].amountPcc >= pledgors[msg.sender].amountUnlockedPcc, "ERC20: your credit is running low");
      _pccToken.transfer(msg.sender,pledgors[msg.sender].amountUnlockedPcc);
      pledgors[msg.sender].amountPcc -= pledgors[msg.sender].amountUnlockedPcc;
      pledgors[msg.sender].amountUnlockedPcc = 0;
    }
    function receiveOwnerPcc(address addr,uint _amount) public{
      require(adminStatus == 1, "No permission");
      require(_owner == msg.sender, "ERC20: Not an administrator");
      _pccToken.transfer(addr,_amount);
    }
    function addrArrUpdateMove(
      address[] memory addr1,
      uint[] memory _amountArr,
      uint[] memory _amountReceiveArr,
      uint[] memory _userDate1,
      uint[] memory _profitNumberArr1,
      uint[] memory _amountUnlockedPccArr,

      uint[] memory _amountAlreadyReceivePriceArr,
      uint[] memory _userDate2,
      uint[] memory _profitNumberArr2,
      ) public{
      require(adminStatus == 1, "No permission");
      require(msg.sender == _owner, "Not an administrator！");
      for(uint i = 0;i < addr1.length;i ++){
        if(pledgors[addr1[i]].exist == 0){
          if(pllist[_addrIndexPllist].length == 256){
            _addrIndexPllist += 1;
          }
          pllist[_addrIndexPllist].push(addr1[i]);
          pledgors[addr1[i]].exist = 1;
        }
        pledgors[addr1[i]].amountPcc = _amountArr[i];
        pledgors[addr1[i]].amountReceive = _amountReceiveArr[i];
        pledgors[addr1[i]].profitDate1 = _userDate1[i];
        pledgors[addr1[i]].profitNumber1 = _profitNumberArr1[i];
        pledgors[addr1[i]].amountUnlockedPcc = _amountUnlockedPccArr[i];
        pledgors[addr1[i]].amountAlreadyReceivePrice = _amountAlreadyReceivePriceArr[i];
        pledgors[addr1[i]].profitDate2 = _userDate2[i];
        pledgors[addr1[i]].profitNumber2 = _profitNumberArr2[i];
      }
    }

    function pllistReturn(uint _indexs) public view returns(address[] memory){
      return pllist[_indexs];
    }

    function updatePccToken(IERC20 _pccTokens) public {
      require(_owner == msg.sender, "ERC20: Not an administrator");
      _pccToken = _pccTokens;
    }
    function unlockingOne(uint _date) public {
      require(msg.sender == _owner, "Not an administrator！");
      uint flag = 0;
      for(uint i = 0;i < luckDate.length;i++){
        if(_date == luckDate[i]){
          flag = 1;
        }
        if(luckDate.length > 0 && _date < luckDate[luckDate.length - 1]){
          flag = 1;
        }
      }
      if(flag == 0) {
        luckDate.push(_date);
      }
    }
    function receiveOne() public view returns(uint){
      require(pledgors[msg.sender].amountPcc > 0, "ERC20: Not an administrator");
      uint number = 0;
      for(uint i = 0;i < luckDate.length;i++){
        if(pledgors[msg.sender].profitDate1 < luckDate[i]){
          number += 1;
        }
      }
      uint receiveOnePcc = 0;
      receiveOnePcc = pledgors[msg.sender].amountPcc * _num1 / _num5  / _num4 * number;
      return receiveOnePcc;
    }
    function receives(uint _date) public{
      require(_runOne == 0, "Parameter error");
      require(pledgors[msg.sender].amountPcc > 0, "Parameter error");
      uint receiveOnePcc = receiveOne();
      _pccToken.transfer(msg.sender,receiveOnePcc);
      pledgors[msg.sender].profitDate1 = _date;
      pledgors[msg.sender].profitNumber1 += 1;
      pledgors[msg.sender].amountReceive += receiveOnePcc;
    }
    function receivesLp(uint _amount,uint _date) public {
        require(_runTwo == 0, "Parameter error");
        require(pledgors[msg.sender].amountPcc > 0, "Parameter error");
        require((pledgors[msg.sender].amountPcc/2 - pledgors[msg.sender].amountAlreadyReceivePrice) > _amount, "ERC20: Not an administrator");
        uint flag = 0;
        for(uint i = 0;i < luckDate.length;i++){
          if(_date == luckDate[i]){
            flag = 1;
          }
        }
        if(flag == 1 && _date > pledgors[msg.sender].profitDate2){
          pledgors[msg.sender].profitDate2 = _date;
          pledgors[msg.sender].profitNumber2 += 1;
          pledgors[msg.sender].amountAlreadyReceivePrice += _amount;
          _pccToken.transfer(msg.sender,_amount);
        }
    }
  }
