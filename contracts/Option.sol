pragma solidity ^0.8.0; 

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";


// interface IERC20 {
//     function totalSupply() external view returns (uint);
//     function balanceOf(address account) external view returns (uint);
//     function transfer(address recipient, uint amount) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint);
//     function approve(address spender, uint amount) external returns (bool);
//     function transferFrom(address sender, address recipient, uint amount) external returns (bool);
//     event Transfer(address indexed from, address indexed to, uint value);
//     event Approval(address indexed owner, address indexed spender, uint value);
// }

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Option {
	using SafeERC20 for IERC20;

	struct SingleOption {
		uint256 amount; 
		uint256 price;
		uint256 waitUntill; // Change name
		address user;
		bool open;
	}

	uint256 constant waitTime = 7 days;
	uint256 constant window = 1 days;

	mapping(uint256 => SingleOption) options;

	address owner;
	address back;

	uint256 optionPrice; // Price for 0.01 Ether 
	uint256 price;

	uint256 totalSupply;
	uint256 totalDept;

	uint256 lastOptionId;

	address constant WETH_ADDRESS = 0x1;
	address constant DAI_ADDRESS = 0x2; 
	address constant UNISWAP_ROUTER = 0x3;

	event AddLiquidity(uint256 amount);
	event RemoveLiquidity(uint256 amount);
	event OptionPriceChange(uint256 newOptionPrice);
	event PriceChange(uint256 newPrice);

	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner");
		_;
	}

	modifier onlyBack() {
		require(msg.sender == back, "Only back");
		_;
	}

	constructor(address _back, address _tokenAddress) {
		owner = msg.sender;
		back = _back;
		tokenAddress = _tokenAddress;
	}	

	function addLiquidity(uint256 amount) external onlyOwner {
		// Transfer ERC20 DAI
		IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

		// Increase total supply? (Can use balanceOf(address(this)). Can it be a problem?)
		totalSupply += amount;
		emit AddLiquidity(amount);
	}

	function removeLiquidity(uint256 amount) external onlyOwner {
		// Check if total supply after removal is greater than totalDept
		require(totalSupply - amount >= totalDept, "You should cover dept");
		// Transfer ERC20 DAI
		IERC20(tokenAddress).safeTransferFrom(address(this), msg.sender, amount);
		// Decrease total supply(If it was increased in addLiquidity)
		totalSupply -= amount;
		emit RemoveLiquidity(amount);
	}

	// amount - amount of ethers
	function buyEthPutOption(uint256 amount) external {
		require(amount >= 10^16, "Not enought ether");
		// Check if contract can produce such option
		uint256 totalCost = amount * price; 
		require(totalDept + totalCost <= totalSupply, "Can't produce such amount of options");
		// Calculate option cost
		uint256 totalOptionPrice = (amount * optionPrice) / 10^16; 
		// Transfer option cost
		IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), totalOptionProice); // Make safe transfer
		// Claim price
		// Create option
		options[lastOptionId].amount = amount;
		options[lastOptionId].price = price;
		options[lastOptionId].user = msg.sender;
		options[lastOptionId].waitUntill = now + waitTime;
		options[lastOptionId].open = true;
		lastOptionId++;

		// Increase total dept
		totalDept += totalCost;
	}

	function releasePutOption(uint256 optionId) external  {
		// Some checks
		require(options[optionId].user == msg.sender, "You can't release option you don't own");
		require(now <= options[optionId].waitUntill && now + window >= options[optionId].waitUntill, "Option is not in oportunity window");
		require(msg.value == options[optionId].amount);
		// Send value to user
		uint256 dept = options[optionId].amount * options[optionId].price;
		options[optionId].open = false;
		IERC20(tokenAddress).safeTransfer(msg.sedner, dept);
		totalDept -= dept;

		// Exchange value on uniswap?? (to costly)
		UniswapChangeEthForDAI();
	}

	function setPrice(uint256 newPrice) external onlyBack { 
		// Just change price
		price = newPrice;
		emit PriceChange(newPrice);
	}

	function setOptionPrice(uint256 newOptionPrice) external onlyOnwer {
		optionPrice = newOptionPrice;
		emit OptionPriceChange(newOptionPrice);
	}

	function _ERC20SafeTransfer(addressaddress from, address to, uint256 amount) internal {
		token.safeTransferFrom(msg.sender, address(this), sendAmount);
	}

	function UniswapChangeEthForDAI() internal {
		IUniswapV2Router01(UNISWAP_ROUTER).swapExactETHForTokens(0, [WETH_ADDRESS, DAI_ADDRESS], address(this), now + 1 days); // Min Value?? Route?? Deadline?? 
	}
}