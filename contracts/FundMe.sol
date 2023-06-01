//get funds from users
//withdraw the funds
//set a minimum funding value in USD

// SPDX-License-Identifier: MIT
// Pragma

pragma solidity ^0.8.0;

// imports

import "./PriceConverter.sol";
import "hardhat/console.sol";

// Error code

error FundMe__NotOwner();

// Interfaces, LIbraries, Contracts

/** @title A contract for crowd funding 
 * @author Samuel Abisuwa
 * @notice This is contract is to demo a sample funding contract
 * @dev This implements Pricefeeds as our library
 */

contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State Variables
    mapping (address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    // making this constant
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner {
           // require(msg.sender == i_owner, "sender is not owner"); below is the prefferred alrernative
            if (msg.sender != i_owner) { revert FundMe__NotOwner(); } 
            _;
        }
         
    // Functions Order: 
    //// Constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
     receive () external payable {
        fund();
    }

    fallback () external payable {
        fund();
    }

    /** @notice This is function funds this contract
     * @dev This implements Pricefeeds as our library
     */

    function fund() public payable {
        //set a minimum fund amount in USD
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more Eth!"); // 1e18 means 1 * 10 ^ 18 ethereum
        // That is 18 decimals 
        s_addressToAmountFunded[msg.sender] = msg.value; 
        s_funders.push(msg.sender);
        // console.log("funder sent required amount of ETH ");

    }
     
    function withdraw() payable public onlyOwner {
        
        for (uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex ++ ){

            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0; 

        }
        
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require (callSuccess, "call failed");
    }

    function cheaperWithdraw() public payable onlyOwner{
        address[] memory funders = s_funders;
        //mappings can't be in memory, sorry!
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
             address funder = funders[funderIndex];
             s_addressToAmountFunded[funder] = 0;
        }
       s_funders = new address[](0);
       (bool success, ) = i_owner.call{value: address(this).balance}("");
       require(success);
    }
       
       function getOwner() public view returns (address) {
         return i_owner;
       }
       function getFunder(uint256 index) public view returns (address) {
         return s_funders[index];
       }
       function getAddressToAmountFunded(address funder) public view returns (uint256) {
         return s_addressToAmountFunded[funder];
       }
       function getPriceFeed() public view returns (AggregatorV3Interface) {
         return s_priceFeed;
       }
        
}