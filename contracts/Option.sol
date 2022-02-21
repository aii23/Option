pragma solidity ^0.8.1; 

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IUniswapV2Router01.sol";
import "./OptionAdministration.sol";
import "hardhat/console.sol";

contract Option is OptionAdministration {
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

    uint256 public totalSupply;
    uint256 public totalDebt;

    uint256 public lastOptionId;

    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant TOKEN_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    event AddLiquidity(uint256 amount);
    event RemoveLiquidity(uint256 amount);

    constructor(address _back) OptionAdministration(_back) {
    }   


    /// @dev Transfer DAI to contract
    /// @param amount DAI amount to be transfered
    function addLiquidity(uint256 amount) external onlyOwner {
        // Transfer ERC20 DAI
        IERC20(TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), amount);

        // Increase total supply? (Can use balanceOf(address(this)). Can it be a problem?)
        totalSupply += amount;
        emit AddLiquidity(amount);
    }

    /// @dev Transfer DAI to owner if final liquidity cover issued options
    /// @param amount DAI amount to be transfered
    function removeLiquidity(uint256 amount) external onlyOwner {
        // Check if total supply after removal is greater than totalDebt
        require(totalSupply - amount >= totalDebt, "You should cover debt");
        // Transfer ERC20 DAI
        IERC20(TOKEN_ADDRESS).safeTransferFrom(address(this), msg.sender, amount);
        // Decrease total supply(If it was increased in addLiquidity)
        totalSupply -= amount;
        emit RemoveLiquidity(amount);
    }

    /// @dev Issue option. Pay option price in DAI
    /// @param amount Ether amount for which option will be issued
    /// @return optionId Issued option id
    function buyEthPutOption(uint256 amount) external returns(uint256 optionId) {
        require(amount >= 10**16, "You cannot buy option for less than 0.01 ether");
        // Check if contract can produce such option
        uint256 totalCost = amount * price / (10**18);

        require(totalCost > 0); 

        require(totalDebt + totalCost <= totalSupply, "Can't produce such amount of options");
        // Calculate option cost
        uint256 totalOptionPrice = (amount * optionPrice) / 10**18; 

        require(totalOptionPrice > 0);

        // Transfer option cost
        IERC20(TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), totalOptionPrice); // Make safe transfer
        // Claim price
        // Create option
        optionId = lastOptionId;
        options[lastOptionId].amount = amount;
        options[lastOptionId].price = price;
        options[lastOptionId].user = msg.sender;
        options[lastOptionId].waitUntill = block.timestamp + waitTime;
        options[lastOptionId].open = true;
        lastOptionId++;

        // Increase total debt
        totalDebt += totalCost;
    }

    /// @dev Sell ether for price mentioned in option
    /// @param optionId Id of the option, which will be used 
    function releasePutOption(uint256 optionId) external payable {
        // Some checks
        require(options[optionId].user == msg.sender, "You can't release option you don't own");

        require(
            block.timestamp >= options[optionId].waitUntill && 
            block.timestamp <= options[optionId].waitUntill + window, 
            "Option is not in oportunity window"
        );
        require(msg.value == options[optionId].amount, "Wrong ether value"); // Can change == to <= 
        require(options[optionId].open, "Option is closed");
        // Send value to user
        uint256 debt = options[optionId].amount * options[optionId].price / 10**18;
        options[optionId].open = false;
        IERC20(TOKEN_ADDRESS).safeTransfer(msg.sender, debt);
        totalDebt -= debt;

        // Exchange value on uniswap?? (to costly)
        UniswapChangeEthForDAI();
    }
/*
    function freePutOption(uint256 optionId) { // ToDo. Free liquidity from debt, if option is outdated

    }
*/

    // function _ERC20SafeTransfer(address from, address to, uint256 amount) internal {
    //  token.safeTransferFrom(msg.sender, address(this), sendAmount);
    // }

    /// @dev Function for swap all ether contract have to DAI
    function UniswapChangeEthForDAI() internal {
        address[] memory route = new address[](2);
        route[0] = WETH_ADDRESS;
        route[1] = TOKEN_ADDRESS;
        // Why solhint is crazy here? 
        IUniswapV2Router01(UNISWAP_ROUTER).swapExactETHForTokens
        {
            // solhint-disable-next-line
            value: address(this).balance
        }
        (
            0, 
            route, 
            address(this), 
            block.timestamp + 1 days
        ); // Min Value?? Route?? Deadline?? 
    }
}