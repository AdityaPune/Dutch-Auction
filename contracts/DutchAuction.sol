// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./SafeMath.sol";

// The auction is initiated with a start date, end date and a start price.
// The price is always known at any time as the linear line connecting the points:
// start date, start price. (startPrice = a · startDate + b)
// end date, 0. (0 = a · end date + b)
// Once someone bids, they are immediately provided with the assets. In a smart contract, delivery is often provided by a privileged function call on behalf of the contract. 
// It is important that the delivery is immediate, as a potential winner might use a flash loan to get the required capital.

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint _itemId
    ) external;
}

contract DutchAuction {

    using SafeMath for uint;

    IERC721 public immutable item;
    uint public immutable itemId;

    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startDate;
    uint public immutable endDate;
    bool public finished = false;

    constructor(
        uint _startingPrice,
        uint _startDate,
        uint _endDate,
        address _item,
        uint _itemId
    ){
        require(_endDate>_startDate,"End Date should be after Start Date");
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startDate = _startDate;
        endDate = _endDate;

        item = IERC721(_item);
        itemId = _itemId;
    }

    modifier isValidAuction() {
        require(finished == false, "Auction has finished");
        require(block.timestamp >= startDate, "Auction hasn't started yet");
        require(block.timestamp < endDate, "Auction has expired");
        _;
    }

    function getPrice() public view returns (uint){
        if(block.timestamp< startDate){
            return startingPrice;
        }    
        // Equation to get price is as follows:
        // y = mx + c
        // y: Price at current timestamp
        // m: Slope. Calculated as (y2-y1/x2-x1) ie: 0 - startingPrice / endDate - startDate
        // x: The current timestamp - startDate
        // c: startingPrice
        
        // uint denom = endDate.sub(startDate);
        // uint m = startingPrice.div(denom);   
        // uint x = block.timestamp - startDate;
        // uint mx = m.mul(x);   
        // uint c = startingPrice;  
        return startingPrice.sub(startingPrice.div(endDate.sub(startDate)).mul(block.timestamp.sub(startDate))); 
    }


    function buy() external isValidAuction payable {
        // require(finished == false, "Auction has finished");
        // require(block.timestamp >= startDate, "Auction hasn't started yet");
        // require(block.timestamp < endDate, "Auction has expired");
        uint price = getPrice();
        require(msg.value >= price, "ETH sent is lesser than the price");

        item.transferFrom(seller, msg.sender, itemId);
        uint refund = msg.value - price;
        if(refund>0){
            payable(msg.sender).transfer(refund);
        }
        payable(seller).transfer(price);
        finished = true;
        // selfdestruct(seller);
    }

}