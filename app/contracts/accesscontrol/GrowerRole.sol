pragma solidity ^0.5.16;

//
// Import the Roles library 
//
import "./Roles.sol";

contract GrowerRole {
  using Roles for Roles.Role;

  //
  // Events
  //
  event GrowerAdded(address indexed account);
  event GrowerRemoved(address indexed account);

  Roles.Role private growers;

  constructor() public {
    _addGrower(msg.sender);
  }

  modifier onlyGrower() {
    require(isGrower(msg.sender));
    _;
  }

  function isGrower(address account) public view returns (bool) {
    return growers.has(account);
  }

  function addGrower(address account) public onlyGrower {
    _addGrower(account);
  }

  function removeGrower() public {
    _removeGrower(msg.sender);
  }

  function _addGrower(address account) internal {
    growers.add(account);
    emit GrowerAdded(account);
  }

  function _removeGrower(address account) internal {
    growers.remove(account);
    emit GrowerRemoved(account);
  }
}

