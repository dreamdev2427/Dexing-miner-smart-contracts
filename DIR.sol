// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './library/IUniswapV2Router02.sol';
import './library/IUniswapV2Factory.sol';
import './library/IUniswapV2Pair.sol';
import './library/SafeMathInt.sol';
import './library/ERC20Detailed.sol';

contract DexingMining is IERC20, Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    event Received(address, uint);
    event Fallback(address, uint);

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _blackList;

    mapping(address => bool) private _whiteList;

    uint256 private _totalSupply;

    string private _name = "Dexing Mining";
    string private _symbol = "DexingM";
    uint8 private _decimals;

    uint256 private _maxPerWalletRate = 2;
    uint256 private _maxPerWallet;

    uint256 private _marketFee = 200;
    uint256 private _equidityFee = 200;
    uint256 private _devFee = 200;
    uint256 private _burnOrLPFee = 100;
    uint256 private _feeDiviser = 1000;

    uint256 private _feeRate = 10000;

    uint256 private _totalBuyFee = 700;
    uint256 private _timeSaleFee = 2100;
    uint256[] private _whaleSaleFee = [2000, 1800, 1500, 1200, 1000];
    uint256[] private _whaleLevel = [200, 150, 100, 50, 25];

    address private _marketWallet = 0x542b06E77DA9c3A16BED909aFa3B9188DBd1D7C6;
    address private _equidityWallet = 0xEe4Dd69979406a3035204752868CB47F4A2C3FD9;
    address private _devWallet = 0x84361F0e0fC4B4eA94B137dB7EF69537a19aCb69;
    address private _burnWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 private tradingStartPoint;
    uint256 private tradingStartDuring;

    IUniswapV2Router02 router;
    address pair;

    bool private pause;
    bool private tradingStart;

    modifier paused() {
        require(!pause, "Contract is paused");
        _;
    }

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        
        // decimals and totalSupply
        _decimals = 18;
        _totalSupply = 90 * 10**7 * 10 **_decimals;
        _maxPerWallet = _totalSupply.mul(_maxPerWalletRate).div(_feeRate);

        // mint tokens to msg.sender
        _balances[ msg.sender] = _totalSupply;

        // whiteList
        _whiteList[_marketWallet] = true;
        _whiteList[_equidityWallet] = true;
        _whiteList[_devWallet] = true;
        _whiteList[msg.sender] = true;

        // router
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = ~uint256(0);

        pause = false;
        
        tradingStartPoint = block.timestamp;
        tradingStartDuring = 3600 * 24 * 2; // 48 hours
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    modifier onlyManager(){
        require(_msgSender() == _devWallet, "not allowed");
        _;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 oldValue = _allowances[msg.sender][spender];

        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(subtractedValue);
        }

        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function _basicTransfer(address from, address to, uint256 amount) paused internal returns (bool) {

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool){
        
        _transferFrom(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool){
        
        _allowances[from][msg.sender] = _allowances[from][
            msg.sender
        ].sub(amount, "Insufficient Allowance");

        _transferFrom(from, to, amount);
        return true;
    }

    function takeBuyFee(
        address sender,
        address recipient,
        uint256 amount
    )internal returns (bool) {

        uint256 value = amount;

        uint256 marketValue = amount.mul(_marketFee).div(_feeDiviser).mul(_totalBuyFee).div(_feeRate);
        uint256 equidityValue = amount.mul(_equidityFee).div(_feeDiviser).mul(_totalBuyFee).div(_feeRate);
        uint256 devValue = amount.mul(_devFee).div(_feeDiviser).mul(_totalBuyFee).div(_feeRate);
        uint256 burnValue = amount.mul(_burnOrLPFee).div(_feeDiviser).mul(_totalBuyFee).div(_feeRate);

        value = value.sub(marketValue).sub(equidityValue).sub(devValue).sub(burnValue);

        _basicTransfer(sender, _marketWallet, marketValue);
        _basicTransfer(sender, _equidityWallet, equidityValue);
        _basicTransfer(sender, _devWallet, devValue);
        _basicTransfer(sender, _burnWallet, burnValue);

        _basicTransfer(sender, recipient, value);

        return true;
    }

    function getWhaleStatusAndSaleFee(address sender) public view returns(bool, uint256){
        
        uint256 balanceOfSender = _balances[sender];

        if( tradingStartPoint + tradingStartDuring > block.timestamp ){
            return (false, _timeSaleFee);
        }

        if( balanceOfSender > _totalSupply.mul(_whaleLevel[0]).div(_feeRate) ){
            require(1==0, "unspecified error");
        }
        else if( balanceOfSender > _totalSupply.mul(_whaleLevel[1]).div(_feeRate)  ){
            return (true, _whaleSaleFee[0]);
        }
        else if( balanceOfSender > _totalSupply.mul(_whaleLevel[2]).div(_feeRate)  ){
            return (true, _whaleSaleFee[1]);
        }
        else if( balanceOfSender > _totalSupply.mul(_whaleLevel[3]).div(_feeRate)  ){
            return (true, _whaleSaleFee[2]);
        }
        else if( balanceOfSender > _totalSupply.mul(_whaleLevel[4]).div(_feeRate)  ){
            return (true, _whaleSaleFee[3]);
        }
        return (false, _whaleSaleFee[4]);

    }

    function addLiquidity(uint256 autoLiquidityAmount) public swapping {

        uint256 amountToLiquify = autoLiquidityAmount.div(2);
        uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

        if( amountToSwap == 0 ) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            _devWallet,
            block.timestamp
        );

        uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

        if (amountToLiquify > 0 && amountETHLiquidity > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                _devWallet,
                block.timestamp
            );
        }
    }

    function takeSaleFee(
        address sender,
        address recipient,
        uint256 amount
    )public returns (bool) {

        uint256 value = amount;
        uint256 saleFee;
        bool isWhale;
        uint256 feeValue;
        
        (isWhale, saleFee) = getWhaleStatusAndSaleFee(sender);

        feeValue = amount.mul(_marketFee).div(_feeDiviser).mul(saleFee).div(_feeRate);
        value = value.sub(feeValue);
        _basicTransfer(sender, _marketWallet, feeValue);

        feeValue = amount.mul(_equidityFee).div(_feeDiviser).mul(saleFee).div(_feeRate);
        value = value.sub(feeValue);
        _basicTransfer(sender, _equidityWallet, feeValue);

        feeValue = amount.mul(_devFee).div(_feeDiviser).mul(saleFee).div(_feeRate);
        _basicTransfer(sender, _devWallet, feeValue);
        value = value.sub(feeValue);

        feeValue = amount.mul(_burnOrLPFee).div(_feeDiviser).mul(saleFee).div(_feeRate);
        
        if( isWhale )
        {         
            _basicTransfer(sender, address(this), feeValue);
            addLiquidity(feeValue);
        } 
        else {
            _basicTransfer(sender, _burnWallet, feeValue);
        }
        value = value.sub(feeValue);

        _basicTransfer(sender, recipient, value);           
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        uint256 value = amount;
        bool excludedAccount = _whiteList[sender] == true || _whiteList[recipient] == true;

        // blackList check
        require( _blackList[sender] == false && _blackList[recipient] == false, "sender or recipient is in blackList" );

        // for whitelist user
        if( excludedAccount || inSwap ){
            _basicTransfer(sender, recipient, value);
        }
        else 
        // buy fee
        if( pair == sender )
        {
            // _basicTransfer(sender, recipient, value);
            takeBuyFee(sender, recipient, amount);            
        }
        else
        // sale fee
        if( pair == recipient )
        {
            // _basicTransfer(sender, recipient, value);
            takeSaleFee(sender, recipient, amount);
        }
        else{
            require( _balances[recipient] + amount < _totalSupply.mul(_whaleLevel[0]).div(_feeRate), "whale!");
            require( block.timestamp > tradingStartPoint + tradingStartDuring, "trading not started!");
            _basicTransfer(sender, recipient, value);
        }        

        return true;
    }

    function setMarketWallet(address newAddress) external onlyOwner{
        _marketWallet = newAddress;
    }

    function getMarketWallet() external view returns(address){
        return _marketWallet;
    }

    function setMarketFee(uint256 newFee) external onlyOwner{
        require(newFee < _feeRate, "invalid percentage!");
        _marketFee = newFee;
    }

    function getMarketFee() external view returns(uint256){
        return _marketFee;
    }

    function setEquidityWallet(address newAddress) external onlyOwner{
        _equidityWallet = newAddress;
    }

    function getEquidityWallet() external view returns(address){
        return _equidityWallet;
    }

    function setEquidityFee(uint256 newFee) external onlyOwner{
        require(newFee < _feeRate, "invalid percentage!");
        _equidityFee = newFee;
    }

    function getEquidityFee() external view returns(uint256){
        return _equidityFee;
    }

    function setDevWallet(address newAddress) external onlyManager{
        _devWallet = newAddress;
    }

    function getDevWallet() external view returns(address){
        return _devWallet;
    }

    function setDevFee(uint256 newFee) external onlyManager{
        require(newFee < _feeRate, "invalid percentage!");
        _devFee = newFee;
    }

    function getDevFee() external view returns(uint256){
        return _devFee;
    }

    function setBurnOrLPFee(uint256 newFee) external onlyOwner{
        require(newFee < _feeRate, "invalid percentage!");
        _burnOrLPFee = newFee;
    }

    function getBurnOrLPFee() external view returns(uint256){
        return _burnOrLPFee;
    }

    function setFeeRate(uint256 newFeeRate) external onlyOwner{
        _feeRate = newFeeRate;
    }

    function getFeeRate() external view returns(uint256){
        return _feeRate;
    }  

    function setPauseStatus(bool newStatus) external onlyOwner{
        pause = newStatus;
    }

    function getPauseStatus() external view returns(bool){
        return pause;
    }

    function setMaxPerWalletRate(uint256 newRate) external onlyOwner{
        require(newRate < _feeRate, "invalid percentage!");
        _maxPerWalletRate = newRate;
        _maxPerWallet = _totalSupply.mul(_maxPerWalletRate).div(_feeRate);
    } 

    function getMaxPerWalletRate() external view returns(uint256){
        return _maxPerWalletRate;
    }

    function setWhiteListStatus(address account, bool status) external onlyManager{
        _whiteList[account] = status;
    }

    function getWhiteListStatus(address account) external view returns(bool){
        return _whiteList[account];
    }

    function setBlackListStatus(address account, bool status) external onlyManager{
        _blackList[account] = status;
    }

    function getBlackListStatus(address account) external view returns(bool){
        return _blackList[account];
    }

    function setTradingStartDuring(uint256 newValue) external onlyOwner{
        tradingStartDuring = newValue;
    }
    
    function getTradingStartDuring() external view returns(uint256){
        return tradingStartDuring;
    }

    function withdraw() external onlyOwner(){
        address payable mine = payable(msg.sender);
        if(address(this).balance > 0) {
            mine.transfer(address(this).balance);
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable { 
        emit Fallback(msg.sender, msg.value);
    }
}
