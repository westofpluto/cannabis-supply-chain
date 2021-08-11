pragma solidity ^0.5.16;

//
// Import the Roles library 
//
import "./Roles.sol";

contract TesterRole {
  using Roles for Roles.Role;

  //
  // Events
  //
  event TesterAdded(address indexed account);
  event TesterRemoved(address indexed account);

  Roles.Role private testers;

  constructor() public {
    _addTester(msg.sender);
  }

  modifier onlyTester() {
    require(isTester(msg.sender));
    _;
  }

  function isTester(address account) public view returns (bool) {
    return testers.has(account);
  }

  function addTester(address account) public onlyTester {
    _addTester(account);
  }

  function removeTester() public {
    _removeTester(msg.sender);
  }

  function _addTester(address account) internal {
    testers.add(account);
    emit TesterAdded(account);
  }

  function _removeTester(address account) internal {
    testers.remove(account);
    emit TesterRemoved(account);
  }
}

