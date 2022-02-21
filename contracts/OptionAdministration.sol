pragma solidity ^0.8.1; 

import "@openzeppelin/contracts/access/Ownable.sol";

contract OptionAdministration is Ownable {

    address back;

    uint256 public optionPrice; // Price for 1 Ether 
    uint256 public price; // Price of 1 Ether

    event OptionPriceChange(uint256 newOptionPrice);
    event PriceChange(uint256 newPrice);

    modifier onlyBack() {
        require(msg.sender == back, "Only back");
        _;
    }

    constructor(address _back) {
        back = _back;
    }

    /// @dev Set price of the ether(in DAI). Only back can call this function 
    /// @param newPrice New price of ether
    function setPrice(uint256 newPrice) external onlyBack { 
        // Just change price
        price = newPrice;
        emit PriceChange(newPrice);
    }

    /// @dev 
    ///     Set price of option for 1 ether. 
    ///     If user whant to buy option for 2.3 ether, he will pay 2.3 * optionPrice DAI
    /// @param newOptionPrice Price of option for 1 ether
    function setOptionPrice(uint256 newOptionPrice) external onlyOwner {
        optionPrice = newOptionPrice;
        emit OptionPriceChange(newOptionPrice);
    }
}
