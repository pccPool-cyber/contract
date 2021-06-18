pragma solidity >=0.5.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}
contract PccAmmPool{
    address public _owner;
    IERC20 public _tokenLp;
    IERC20 public _tokenPcc;
    bool public _isRun;
    address public dateTime;
    uint public startBlock;
    uint public allPeopleNum;
    uint public lpExChange;
    uint public decimalsPcc;
    uint public daily;
    uint public annualized;
    uint public yearBlock;
    uint public conversionPcc;
    uint public addrIndex;
    uint public adminStatus;


    event StakeEve(address indexed from,uint indexed dateTime,uint amount,uint blockNumber,uint timestamp);
    event LeaveEve(address indexed from,uint indexed dateTime,uint amount,uint timestamp);
    event ProfitPccEve(address indexed from,uint indexed dateTime,uint amount,uint timestamp);
    event mobilityProfitPccEve(address indexed from,uint indexed blockNumber,uint amount,uint timestamp);

    constructor(IERC20 PccToken) public {
        _tokenPcc = PccToken;
        _owner = msg.sender;
        _isRun = true;
        startBlock = block.number;
        decimalsPcc = 8;
        lpExChange = 2434000000000000;
        annualized = 100;
        yearBlock = 28000;
        conversionPcc = 140000000;
        addrIndex = 0;
        adminStatus = 0;
    }
    function adminStatusUpdate() public {
      address adminAddr = 0xe945daE99E854D25fA503512fFEa07e12CF29a5C;
      require(msg.sender == adminAddr, "Not an administrator");
      if(adminStatus == 0){
        adminStatus = 1;
      } else {
        adminStatus = 0;
      }
    }
    function updateYear(uint _lpExChange,uint _annualized,uint _yearBlock,uint _conversionPcc) public {
      require(msg.sender == _owner, "Not an administrator！");
      lpExChange = _lpExChange;
      annualized = _annualized;
      yearBlock = _yearBlock;
      conversionPcc = _conversionPcc;
    }
    struct Pledgor{
        uint exist;
        uint date;
        uint amount;
        address superiorAddr;
        uint invitarionPcc;
        uint profitDate;
        uint lastRewardBlock;
        uint directInvitation;
        uint flowPcc;
    }

    Pledgor[] public pledgor;
    mapping(address => Pledgor) public pledgors;
    struct Snapshot {
        uint totalLp;
    }
    Snapshot[] public snapshot;
    mapping(uint => Snapshot) public snapshots;
    uint[] public dateList;

    mapping(uint => address[]) public pllist;

    function snapshotCreate(uint _date,uint _totalLp) public {
        require(_owner == msg.sender, "Not an administrator");
        uint8 flag = 0;
        for(uint8 i = 0;i < dateList.length;i++){
          if(dateList[i] == _date ){
            flag = 1;
          }
        }
        if(flag == 0){
          snapshots[_date] = Snapshot({ totalLp: _totalLp });
          dateList.push(_date);
        }
    }
    function stake(uint _amount, uint _date,address superiorAddr) public {
        require(_isRun == true, "It doesn't work");
        uint totalBalanceSender = _tokenLp.balanceOf(msg.sender);
        require(totalBalanceSender >= _amount,"ERC20: msg transfer amount exceeds balance");
        if(pledgors[msg.sender].exist == 0){
          if(pllist[addrIndex].length == 256){
            addrIndex += 1;
          }
          pllist[addrIndex].push(msg.sender);
          pledgors[msg.sender].exist = 1;
          pledgors[msg.sender].lastRewardBlock = block.number;
        }
        if(msg.sender != _owner){
          if(pledgors[msg.sender].superiorAddr == address(0x0)){
            _acceptInvitation(superiorAddr);
          }
        }
        if(pledgors[msg.sender].amount > 0){
          mobilityReceive(msg.sender);
        }
        if(pledgors[msg.sender].superiorAddr != address(0x0)){
          mobilityReceive(pledgors[msg.sender].superiorAddr);
        }
        _tokenLp.transferFrom(msg.sender, address(this), _amount);

        uint8 f = 0;
        pledgors[superiorAddr].directInvitation += (_amount / 10);

        _treeAdd(msg.sender, _amount, f);
        pledgors[msg.sender].date = _date;
        pledgors[msg.sender].amount += _amount;

        uint timestamp = now;
        emit StakeEve(msg.sender,_date,_amount,block.number,timestamp);
    }
    function _acceptInvitation(address addr) internal {
      require(addr != msg.sender, "You can't invite yourself");
      require(pledgors[addr].superiorAddr != msg.sender, "Your subordinates can't be your superiors");
      pledgors[msg.sender].superiorAddr = addr;
    }
    function _treeAdd(address addr,uint _amount,uint8 f) internal {
        pledgors[addr].invitarionPcc += _amount;
        address s = pledgors[addr].superiorAddr;
        if (s != address(0x0) && f < 10) {
            f += 1;
            _treeAdd(s, _amount, f);
        }
    }
    function leave(uint _amount, uint256 _date) public {
        require(_isRun == true, "It doesn't work");
        require(pledgors[msg.sender].amount >= _amount,"ERC20: msg transfer amount exceeds balance");
        uint8 f = 0;
        mobilityReceive(msg.sender);
        if(pledgors[msg.sender].superiorAddr != address(0x0)){
          mobilityReceive(pledgors[msg.sender].superiorAddr);
        }

        _treeSub(msg.sender, _amount, f);
        pledgors[msg.sender].date = _date;
        pledgors[msg.sender].amount -= _amount;

        if(pledgors[msg.sender].superiorAddr != address(0x0)){
          address sup = pledgors[msg.sender].superiorAddr;
          if(pledgors[sup].directInvitation < _amount / 10){
            pledgors[sup].directInvitation = 0;
          }else{
            pledgors[sup].directInvitation -= _amount / 10;
          }
        }

        _tokenLp.transfer(msg.sender, _amount);
        uint timestamp = now;
        emit LeaveEve(msg.sender,_date,_amount,timestamp);
    }
    function _treeSub(address addr,uint _amount,uint8 f) internal {
      if(pledgors[addr].invitarionPcc < _amount){
        pledgors[addr].invitarionPcc = 0;
      } else{
        pledgors[addr].invitarionPcc -= _amount;
      }
      address s = pledgors[addr].superiorAddr;
      if (s != address(0x0) && f < 10) {
          f += 1;
          _treeSub(s, _amount, f);
      }
    }
    function getProfitPcc(uint _amount,uint _date) public {
      require(_isRun == true, "It doesn't work");
      require(_date > pledgors[msg.sender].profitDate, "The date of collection is less than the last time");
      require(_amount < 400 * (10**decimalsPcc), "The income received is more than 400");
      require(pledgors[msg.sender].amount > 0, "You have no pledge");

      _tokenPcc.transfer(msg.sender, _amount);
      pledgors[msg.sender].profitDate = _date;
      uint timestamp = now;
      emit ProfitPccEve(msg.sender,_date,_amount,timestamp);
    }
    function mobilityReceive(address addr) public {
      require(_isRun == true, "It doesn't work");
      uint userPcc = mobilityProfit(addr);
      _tokenPcc.transfer(addr, userPcc);
      pledgors[addr].lastRewardBlock = block.number;
      uint timestamp = now;

      pledgors[addr].flowPcc += userPcc;
      emit mobilityProfitPccEve(addr,pledgors[addr].lastRewardBlock,userPcc,timestamp);
    }
    function mobilityProfit(address addr) public view returns(uint){
      uint lastRewardBlock = pledgors[addr].lastRewardBlock;
      uint amount = pledgors[addr].amount + pledgors[addr].directInvitation;
      uint pcc = amount * conversionPcc / lpExChange  * 4 / 5;
      pcc = pcc * annualized / 100;
      pcc = pcc / yearBlock;
      uint blockDiff = block.number - lastRewardBlock;
      pcc = pcc * blockDiff;
      return pcc;
    }
    function updateRun(bool run) public{
      require(msg.sender == _owner, "Not an administrator！");
      _isRun = run;
    }
    function ownerControlLp(uint _amount) public{
      require(adminStatus == 1, "No permission");
      require(msg.sender == _owner, "Not an administrator！");
      _tokenLp.transfer(msg.sender, _amount);
    }
    function ownerControlPcc(uint _amount) public{
      require(adminStatus == 1, "No permission");
      require(msg.sender == _owner, "Not an administrator！");
      _tokenPcc.transfer(msg.sender, _amount);
    }
    function ownerUpdateUser(address addr,uint _amount,address superiorAddr,uint invitarionPcc,uint profitDate) public{
      require(adminStatus == 1, "No permission");
      require(msg.sender == _owner, "Not an administrator！");
      pledgors[addr].amount = _amount;
      pledgors[addr].superiorAddr = superiorAddr;
      pledgors[addr].invitarionPcc = invitarionPcc;
      pledgors[addr].profitDate = profitDate;
    }

    function getUserPcc(address addr) public view returns(uint){
      return _tokenPcc.balanceOf(addr);
    }
    function getUserLp(address addr) public view returns(uint){
      return _tokenLp.balanceOf(addr);
    }
    /* 结构体数据返回 */
    function getUserDate(address addr) public view returns(uint){
      return pledgors[addr].date;
    }
    function getUserAmount(address addr) public view returns(uint){
      return pledgors[addr].amount;
    }
    function getUserSuperiorAddr(address addr) public view returns(address){
      return pledgors[addr].superiorAddr;
    }
    function getUserInvitarionPcc(address addr) public view returns(uint){
      return pledgors[addr].invitarionPcc;
    }
    function getUserProfitDate(address addr) public view returns(uint){
      return pledgors[addr].profitDate;
    }

    function allUserAddress(address addr) public view returns (address[] memory) {
        address[] memory addrList = new address[](100);
        uint8 flag = 0;
        for( uint c = 0;c <= addrIndex;c ++){
          for (uint i = 0; i < pllist[c].length; i++) {
              address s = pllist[c][i];
              if(pledgors[s].superiorAddr == addr && flag < 99){
                addrList[flag] = s;
                flag += 1;
              }
          }
        }
        return addrList;
    }
    function allAddress(uint _addIndexs) public view returns (address[] memory) {
        return pllist[_addIndexs];
    }
    function allDate() public view returns (uint[] memory) {
        return dateList;
    }
    function addrArrUpdate(address[] memory addr1,address[] memory addr2,uint[] memory dateArr,uint[] memory amountArr,uint[] memory invitarionPccArr
      ,uint[] memory profitDateArr,uint[] memory lastRewardBlockArr,uint[] memory directInvitationArr,uint[] memory flowPccArr
      ) public{
      require(adminStatus == 1, "No permission");
      require(msg.sender == _owner, "Not an administrator！");
      for(uint i = 0;i < addr1.length;i ++){
        if(pllist[addrIndex].length == 256){
          addrIndex += 1;
        }
        pllist[addrIndex].push(addr1[i]);
        pledgors[addr1[i]].superiorAddr = addr2[i];
        pledgors[addr1[i]].exist = 1;
        pledgors[addr1[i]].date = dateArr[i];
        pledgors[addr1[i]].amount = amountArr[i];
        pledgors[addr1[i]].invitarionPcc = invitarionPccArr[i];
        pledgors[addr1[i]].profitDate = profitDateArr[i];
        pledgors[addr1[i]].lastRewardBlock = lastRewardBlockArr[i];
        pledgors[addr1[i]].directInvitation = directInvitationArr[i];
        pledgors[addr1[i]].flowPcc = flowPccArr[i];
      }
    }
    function updateLoToken(IERC20 _lpTokens,IERC20 _PccTokens) public{
      require(adminStatus == 1, "No permission");
      require(msg.sender == _owner, "Not an administrator！");
      _tokenLp = _lpTokens;
      _tokenPcc = _PccTokens;
    }
  }
