pragma solidity ^0.5.16;

import '../base/SupplyChainBase.sol';

contract SupplyChain is SupplyChainBase {

  // Define a function 'fetchFarmInfo' that fetches the data
  function fetchFarmInfo(address originGrowerID) public view returns (
      string  memory originFarmName,
      string  memory originFarmInformation,
      string  memory originFarmLatitude,
      string  memory originFarmLongitude
  ) {

    originFarmName = farmsInfo[originGrowerID].originFarmName;
    originFarmInformation = farmsInfo[originGrowerID].originFarmInformation;
    originFarmLatitude = farmsInfo[originGrowerID].originFarmLatitude;
    originFarmLongitude = farmsInfo[originGrowerID].originFarmLongitude;      
    return 
    (
      originFarmName,
      originFarmInformation,
      originFarmLatitude,
      originFarmLongitude
    );
  }

  function fetchBaleAddressInfo(uint _upc, uint _baleId) public view returns (
      address ownerID,
      address originGrowerID,
      address testerID,   
      address distributorID,   
      address retailerID
  ) {
    ownerID = bales[_upc][_baleId].baleAddresses.ownerID;
    originGrowerID = bales[_upc][_baleId].baleAddresses.originGrowerID;
    testerID = bales[_upc][_baleId].baleAddresses.testerID;
    distributorID = bales[_upc][_baleId].baleAddresses.distributorID;
    retailerID = bales[_upc][_baleId].baleAddresses.retailerID;

    return 
    (
      ownerID,
      originGrowerID,
      testerID,
      distributorID,
      retailerID
    );
  }

  // Define a function 'fetchBaleInfo' that fetches the data
  function fetchBaleInfo(uint _upc, uint _baleId) public view returns (
      uint    itemSKU,
      string  memory strainName,
      uint    thcPct,
      uint    cbdPct,
      string  memory productNotes,
      uint    growerPrice,
      uint    distributorPrice,
      uint    numRetail,  
      address ownerID, 
      string  memory stateStr
  ) {
    // Assign values to the parameters
    itemSKU = bales[_upc][_baleId].sku;
    strainName = getStrainString(getStrainFromUPC(_upc));
    thcPct = bales[_upc][_baleId].thcPct;
    cbdPct = bales[_upc][_baleId].cbdPct;
    productNotes = bales[_upc][_baleId].productNotes;
    growerPrice = bales[_upc][_baleId].growerPrice;
    distributorPrice = bales[_upc][_baleId].distributorPrice;
    numRetail = bales[_upc][_baleId].numRetailProducts;
    ownerID = bales[_upc][_baleId].baleAddresses.ownerID;
    stateStr=getStateString(bales[_upc][_baleId].itemState);

    return 
    (
      itemSKU,
      strainName,
      thcPct,
      cbdPct,
      productNotes,
      growerPrice,
      distributorPrice,
      numRetail,
      ownerID,  
      stateStr
    );
  }

  //
  // Define a function 'fetchBaleRetailIds' that fetches the array of retailId properties for the retail products from this bale
  //
  function fetchBaleRetailIds(uint _upc, uint _baleId) public view returns (uint[] memory retailIds) {
      uint n = bales[_upc][_baleId].numRetailProducts;
      if (n > 0) {
          retailIds = new uint[](n);
          for (uint i=0; i<n; i++) {
              retailIds[i] = retailItemsForBale[_upc][_baleId][i].retailId;
          }
      } else {
          retailIds = new uint[](0);
      }
      return retailIds;
  }

  //
  // Define a function 'fetchRetailItemInfo' that fetches the data
  //
  function fetchRetailItemInfo(uint _upc, uint _baleId, uint _retailId) public view returns (
      uint    itemSKU,
      uint    retailPrice,
      address ownerID,
      address retailerID,
      address consumerID,
      string  memory stateStr
  ) {
    // Assign values to the parameters
    itemSKU = retailItems[_upc][_baleId][_retailId].sku;
    retailPrice = retailItems[_upc][_baleId][_retailId].retailPrice;
    ownerID = retailItems[_upc][_baleId][_retailId].ownerID;
    retailerID = bales[_upc][_baleId].baleAddresses.retailerID;
    consumerID = retailItems[_upc][_baleId][_retailId].consumerID;

    stateStr=getStateString(retailItems[_upc][_baleId][_retailId].itemState);

    return 
    (
      itemSKU,
      retailPrice,  
      ownerID,
      retailerID,
      consumerID,
      stateStr
    );
  }

}
