pragma solidity ^0.8.0;

contract Item {
    
    uint public itemPrice;
    uint public index;
    uint public pricePaid;
    ItemManager parentContract;
    
    constructor(uint _itemPrice, uint _index, ItemManager _parentContract) {
        itemPrice = _itemPrice;
        index = _index;
        parentContract = _parentContract;
    }
    
    receive() external payable {
        require(pricePaid == 0);
        require(itemPrice == msg.value);
        pricePaid += msg.value;
        (bool success, ) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("pay(uint256)",index));
        require(success);
    }
    
    // fallback() external {}
}


contract ItemManager {
    
    enum DeliveryState {Created, Paid, Delivered}
    
    struct S_Item {
        Item item;
        string identifier;
        uint itemPrice;
        DeliveryState state;
    }
    
    mapping (uint => S_Item) public items;
    
    uint itemIndex;
    
    event SupplychainStep(uint itemIndex, DeliveryState step, address itemAddress);
    
    function create(string memory _identifier, uint _price) public {
        Item item = new Item(_price, itemIndex, this);
        items[itemIndex] = S_Item(item, _identifier, _price, DeliveryState.Created);
        emit SupplychainStep(itemIndex, items[itemIndex].state, address(item));
        itemIndex ++;
    }
    
    function pay(uint _itemIndex) public payable {
        require(items[_itemIndex].itemPrice == msg.value, "full payment is required");
        require(items[_itemIndex].state == DeliveryState.Created, "item is further in the supply chain");
        items[_itemIndex].state = DeliveryState.Paid;
        emit SupplychainStep(_itemIndex, items[_itemIndex].state, address(items[_itemIndex].item));
        
    }
    
    function deliver(uint _itemIndex) public {
        require(items[_itemIndex].state == DeliveryState.Paid, "item is further in the supply chain");
        items[_itemIndex].state = DeliveryState.Delivered;
        emit SupplychainStep(_itemIndex, items[_itemIndex].state, address(items[_itemIndex].item));

    } 
    
    
}
