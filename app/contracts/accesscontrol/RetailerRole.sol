pragma solidity ^0.5.16;

//
// Import the Roles library 
//
import "./Roles.sol";

contract RetailerRole {
  using Roles for Roles.Role;

  //
  // Events
  //
  event RetailerAdded(address indexed account);
  event RetailerRemoved(address indexed account);

  Roles.Role private retailers;

  constructor() public {
    _addRetailer(msg.sender);
  }

  modifier onlyRetailer() {
    require(isRetailer(msg.sender));
    _;
  }

  function isRetailer(address account) public view returns (bool) {
    return retailers.has(account);
  }

  function addRetailer(address account) public onlyRetailer {
    _addRetailer(account);
  }

  function removeRetailer() public {
    _removeRetailer(msg.sender);
  }

  function _addRetailer(address account) internal {
    retailers.add(account);
    emit RetailerAdded(account);
  }

  function _removeRetailer(address account) internal {
    retailers.remove(account);
    emit RetailerRemoved(account);
  }
}

