// 8888888b.  8888888888 Y88b   d88P 8888888 888b    888  .d8888b.       888b     d888 8888888 888b    888 8888888888 8888888b.  
// 888  "Y88b 888         Y88b d88P    888   8888b   888 d88P  Y88b      8888b   d8888   888   8888b   888 888        888   Y88b 
// 888    888 888          Y88o88P     888   88888b  888 888    888      88888b.d88888   888   88888b  888 888        888    888 
// 888    888 8888888       Y888P      888   888Y88b 888 888             888Y88888P888   888   888Y88b 888 8888888    888   d88P 
// 888    888 888           d888b      888   888 Y88b888 888  88888      888 Y888P 888   888   888 Y88b888 888        8888888P"  
// 888    888 888          d88888b     888   888  Y88888 888    888      888  Y8P  888   888   888  Y88888 888        888 T88b   
// 888  .d88P 888         d88P Y88b    888   888   Y8888 Y88b  d88P      888   "   888   888   888   Y8888 888        888  T88b  
// 8888888P"  8888888888 d88P   Y88b 8888888 888    Y888  "Y8888P88      888       888 8888888 888    Y888 8888888888 888   T88b       

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size; assembly {
            size := extcodesize(account)
        } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target,bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {   
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}
//libraries
struct User {
    uint256 startDate;
    uint256 divs;
    uint256 refBonus;
    uint256 totalInits;
    uint256 totalWiths;
    uint256 totalAccrued;
    uint256 lastWith;
    uint256 timesCmpd;
    uint256 keyCounter;
    Depo [] depoList;
}
struct Depo {
    uint256 key;
    uint256 depoTime;
    uint256 amt;
    address ref;
    bool initialWithdrawn;
}
struct Main {
    uint256 ovrTotalDeps;
    uint256 ovrTotalWiths;
    uint256 users;
    uint256 compounds;
}
struct DivPercs{
    uint256 daysInSeconds; // updated to be in seconds
    uint256 divsPercentage;
}
struct FeesPercs{
    uint256 daysInSeconds;
    uint256 feePercentage;
}
contract FTMGrowGarden {
    using SafeMath for uint256;
    uint256 constant launch = 0;
  	uint256 constant hardDays = 86400;
    uint256 constant minStakeAmt = 50 * 10**6;
    uint256 constant percentdiv = 1000;
    uint256 refPercentage = 100;
    uint256 devPercentage = 100;
    mapping (address => mapping(uint256 => Depo)) public DeposMap;
    mapping (address => User) public UsersKey;
    mapping (uint256 => DivPercs) public PercsKey;
    mapping (uint256 => FeesPercs) public FeesKey;
    mapping (uint256 => Main) public MainKey;
    using SafeERC20 for IERC20;
    IERC20 public USDC;
    address public owner;

    constructor() {
        owner = msg.sender;
        PercsKey[10] = DivPercs(864000, 30);
        PercsKey[20] = DivPercs(1728000, 35);
        PercsKey[30] = DivPercs(2592000, 40);
        PercsKey[40] = DivPercs(3456000, 45);
        PercsKey[50] = DivPercs(4320000, 50);
        PercsKey[60] = DivPercs(5184000, 55);
        PercsKey[70] = DivPercs(6048000, 60);
        PercsKey[80] = DivPercs(6912000, 65);
        PercsKey[90] = DivPercs(7776000, 70);
        PercsKey[100] = DivPercs(8640000, 100);

        FeesKey[10] = FeesPercs(864000, 200);
        FeesKey[20] = FeesPercs(1728000, 190);
        FeesKey[30] = FeesPercs(2592000, 180);
        FeesKey[40] = FeesPercs(3456000, 170);
        FeesKey[50] = FeesPercs(4320000, 160);
        FeesKey[60] = FeesPercs(5184000, 150);
        FeesKey[70] = FeesPercs(6048000, 140);
        FeesKey[80] = FeesPercs(6912000, 130);
        FeesKey[90] = FeesPercs(7776000, 120);
        FeesKey[100] = FeesPercs(8640000, 100);

        USDC = IERC20(0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c);
    }
    
    function stake(uint256 amtx, address ref) external {
        require(block.timestamp >= launch, "App did not launch yet.");
        require(ref != msg.sender, "You cannot refer yourself!");
        require(amtx >= minStakeAmt, "You should stake at least 50.");
        USDC.safeTransferFrom(msg.sender, address(this), amtx);
        User storage user = UsersKey[msg.sender];
        User storage user2 = UsersKey[ref];
        Main storage main = MainKey[1];
        if (user.lastWith == 0){
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
        }
        uint256 userStakePercentAdjustment = 1000 - devPercentage;
        uint256 adjustedAmt = amtx.mul(userStakePercentAdjustment).div(percentdiv); 
        uint256 stakeFee = amtx.mul(devPercentage).div(percentdiv); 
        
        user.totalInits += adjustedAmt; 
        uint256 refAmtx = adjustedAmt.mul(refPercentage).div(percentdiv);
        if (ref != address(0)) {
            user2.refBonus += refAmtx;
        }

        user.depoList.push(Depo({
            key: user.depoList.length,
            depoTime: block.timestamp,
            amt: adjustedAmt,
            ref: ref,
            initialWithdrawn: false
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        main.users += 1;
        
        USDC.safeTransfer(owner, stakeFee);
    }

    function userInfo() view external returns (Depo [] memory depoList) {
        User storage user = UsersKey[msg.sender];
        return(
            user.depoList
        );
    }

    function withdrawDivs() external returns (uint256 withdrawAmount) {
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        uint256 x = calcdiv(msg.sender);
      
      	for (uint i = 0; i < user.depoList.length; i++){
          if (user.depoList[i].initialWithdrawn == false) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        uint256 userWithdrawPercentAdjustment = 1000 - devPercentage;
        uint256 adjustedAmt = x.mul(userWithdrawPercentAdjustment).div(percentdiv); 
        uint256 withdrawFee = x.mul(devPercentage).div(percentdiv);

        main.ovrTotalWiths += x;
        user.lastWith = block.timestamp;

        USDC.safeTransfer(msg.sender, adjustedAmt);
        USDC.safeTransfer(owner, withdrawFee);

        return x;
    }

    function withdrawInitial(uint256 key) external {
      	  
      	User storage user = UsersKey[msg.sender];
				
      	require(user.depoList[key].initialWithdrawn == false, "This has already been withdrawn.");
      
        uint256 initialAmt = user.depoList[key].amt; 
        uint256 currDays1 = user.depoList[key].depoTime;
        uint256 currTime = block.timestamp;
        uint256 currDays = currTime - currDays1;
        uint256 transferAmt;
      	
        if (currDays < FeesKey[10].daysInSeconds){ // LESS THAN 10 DAYS STAKED
            uint256 minusAmt = initialAmt.mul(FeesKey[10].feePercentage).div(percentdiv); //20% fee
           	
          	uint256 dailyReturn = initialAmt.mul(PercsKey[10].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
          	
          	transferAmt = initialAmt + currentReturn - minusAmt;
          
            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC.safeTransfer(msg.sender, transferAmt);

        } else if (currDays >= FeesKey[10].daysInSeconds && currDays < FeesKey[20].daysInSeconds){ // BETWEEN 10 and 20 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[20].feePercentage).div(percentdiv); //19% fee
						
          	uint256 dailyReturn = initialAmt.mul(PercsKey[20].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[20].daysInSeconds && currDays < FeesKey[30].daysInSeconds){ // BETWEEN 20 and 30 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[30].feePercentage).div(percentdiv); //18% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[30].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[30].daysInSeconds && currDays < FeesKey[40].daysInSeconds){ // BETWEEN 30 and 40 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[40].feePercentage).div(percentdiv); //17% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[40].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);
          
        } else if (currDays >= FeesKey[40].daysInSeconds && currDays < FeesKey[50].daysInSeconds){ // BETWEEN 40 and 50 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[50].feePercentage).div(percentdiv); //16% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[50].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[50].daysInSeconds && currDays < FeesKey[60].daysInSeconds){ // BETWEEN 50 and 60 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[60].feePercentage).div(percentdiv); //15% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[60].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[60].daysInSeconds && currDays < FeesKey[70].daysInSeconds){ // BETWEEN 60 and 70 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[70].feePercentage).div(percentdiv); //14% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[70].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);
        } else if (currDays >= FeesKey[70].daysInSeconds && currDays < FeesKey[80].daysInSeconds){ // BETWEEN 70 and 80 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[80].feePercentage).div(percentdiv); //13% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[80].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);
        } else if (currDays >= FeesKey[80].daysInSeconds && currDays < FeesKey[90].daysInSeconds){ // BETWEEN 80 and 90 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[90].feePercentage).div(percentdiv); //12% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[90].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);
        } else if (currDays >= FeesKey[90].daysInSeconds){ // 90+ DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[100].feePercentage).div(percentdiv); //10% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[100].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC.safeTransfer(msg.sender, transferAmt);
            USDC.safeTransfer(owner, minusAmt);
        } else {
            revert("Could not calculate the # of days you've been staked.");
        }
        
    }
    function withdrawRefBonus() external {
        User storage user = UsersKey[msg.sender];
        uint256 amtz = user.refBonus;
        user.refBonus = 0;

        USDC.safeTransfer(msg.sender, amtz);
    }

    function stakeRefBonus() external { 
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        require(user.refBonus > 10);
      	uint256 referralAmount = user.refBonus;
        user.refBonus = 0;
        address ref = address(0);
				
        user.depoList.push(Depo({
            key: user.keyCounter,
            depoTime: block.timestamp,
            amt: referralAmount,
            ref: ref, 
            initialWithdrawn: false
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
    }

    function calcdiv(address dy) public view returns (uint256 totalWithdrawable) {
        User storage user = UsersKey[dy];	

        uint256 with;
        
        for (uint256 i = 0; i < user.depoList.length; i++){	
            uint256 elapsedTime = block.timestamp.sub(user.depoList[i].depoTime);

            uint256 amount = user.depoList[i].amt;
            if (user.depoList[i].initialWithdrawn == false){
                if (elapsedTime <= PercsKey[10].daysInSeconds){ 
                    uint256 dailyReturn = amount.mul(PercsKey[10].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[10].daysInSeconds && elapsedTime <= PercsKey[20].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[20].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[30].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[40].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[50].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[50].daysInSeconds && elapsedTime <= PercsKey[60].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[60].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[60].daysInSeconds && elapsedTime <= PercsKey[70].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[70].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[70].daysInSeconds && elapsedTime <= PercsKey[80].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[80].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[80].daysInSeconds && elapsedTime <= PercsKey[90].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[90].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[90].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[100].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                
            } 
        }
        return with;
    }

    function compound() external {
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];

        uint256 y = calcdiv(msg.sender);

        for (uint i = 0; i < user.depoList.length; i++){
          if (user.depoList[i].initialWithdrawn == false) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        user.depoList.push(Depo({
              key: user.keyCounter,
              depoTime: block.timestamp,
              amt: y,
              ref: address(0), 
              initialWithdrawn: false
          }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        main.compounds += 1;
        user.lastWith = block.timestamp;  
    }
}