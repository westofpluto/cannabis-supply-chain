pragma solidity ^0.5.16;

import '../core/Ownable.sol';
import '../accesscontrol/GrowerRole.sol';
import '../accesscontrol/TesterRole.sol';
import '../accesscontrol/DistributorRole.sol';
import '../accesscontrol/RetailerRole.sol';
import '../accesscontrol/ConsumerRole.sol';

contract SupplyChainBase is Ownable, GrowerRole, TesterRole, DistributorRole, RetailerRole, ConsumerRole {
  //
  // define structs for items of interest
  // We assume our cannabis is grown in bulk in one of 4 varieties/strains:
  // 1. Trippy Purple Bubblegum Haze (a sativa)
  // 2. Vulcan Mind Melt (a hybrid)
  // 3. Catatonic Couchlock Kush (an indica)
  // 4. Snoozy Woozy (a high CBD, lower THC strain)
  // We can assign each strain a UPC which differentiates it from other strains.
  // We assume a very simple mapping between UPC and Strain: the UPC is always a positive integer and 
  // the ending digit indicates the Strain as follows:
  //  - UPC ending in 0,1,2 = Trippy Purple Bubblegum Haze
  //  - UPC ending in 3,4,5 = Vulcan Mind Melt
  //  - UPC ending in 6,7 = Catatonic Couchlock Kush
  //  - UPC ending in 8,9 = Snoozy Woozy
  // So from the UPC we can always find the Strain, and in the UI we specifiy the Strain by choosing the UPC. 
  //    
  // Like coffee, cannabis is a bulk item that gets segmented into retail-sized units later in the process.
  // So, an Item in cannabis (or coffee) must also indicate the size we are talking about. Furthermore,
  // a single bulk quantity (bale) of cannabis will be processed into a large number of individually sized
  // retail packages, so there will be N retail-sized packages for each bale. None of this logic was properly
  // considered by Udacity in their starter code, so it is added here.
  // 
  // How I Handle IDs:
  // - Each strain is associated with one or more UPC's. The last digit of the UPC indicates the strain.
  // - The UPC for a given strain refers to some undetermined bulk quantity of canabis. In order for
  //   the cannabis to be any sort of "item", it must be segmented first into some number of (say) 10 kg "bales".
  // - Each bale from the above bulk cannabis will be uniquely identified by the UPC and a bale ID (a uint).
  //   It is perfectly possible and acceptable for two bales with different UPCs to have the same value for bale ID,
  //   ie the bale ID is unique only to the UPC. Again, it is the combination of UPC and bale ID that uniquely identifies the bale.
  // - A sample is just a small quantity from a given bale that is sent for testing. Each sample has its own
  //   sample ID that is unique only to the bale. In our simplified chain, we will only ever have a single sample from a given
  //   bale.
  // - When the bale is processed, it creates some number of retail-sized items. In real life, a bale
  //   would create a large number (thousands) of retail-sized (say 3 gram) retail packages. For simplicity
  //   in this project, I reduce that number drastically to 10. In other words, when the cannabis is processed
  //   it gets converted from a single bale into 10 retail sized (3 gram) retail products. 
  // - Each retail (3 gram) jar of canabis has its own item ID that is unique only to that bale. The combination of
  //   item ID, bale ID, and UPC uniquely determines the retail item (the liitle 3 gram jar of weed you buy at the dispensary).
  //
  // 

  // Define a variable called 'autosku' which is how we automatically generate SKU.
  // In real life, various parties would create their own values, but to keep it simple we just auto-generate this
  uint  autosku;

  enum Strain {
      TrippyPurpleBubblegumHaze,  // 0
      VulcanMindMelt,             // 1
      CatatonicCouchlockKush,     // 2
      SnoozyWoozy                 // 3
  }

  //
  // The cannabis starts out as a bale-sized chunk of plants. It gets processed into a an actual bale (say a 10kg sized chunk).
  // Next it  gets sampled, tested, and eventually packed.
  // When it is packed, it basically ceases to exist as a bale, instead it is now in the form of a large number of retail sized packages
  // In this simplified supply chain, each bale creates exactly 10 retail packages (the number in real life will be much larger).
  //
  enum State {
    Harvested,              // 0   Bale-sized cannabis is now in the form of a bunch of harvested plants
    Processed,              // 1   Plants processed to extract the flower and remove unusable matter, formed into a bale
    Sampled,                // 2   Bale is sampled for testing. Sample is created with state Sampled
    SampleRequested,        // 3   Tester has requested the sample for testing.  
    SentToTester,           // 4   Bale is sampled and the sample is sent to the tester to check quality, THC and CBD content etc
    ReceivedByTester,       // 5   Sample received by tester
    InTesting,              // 6   Sample in testing
    Approved,               // 7   Sample approved, approval sent back to grower/farmer 
    Productized,            // 8   Bale of cannabis productized/converted to retail packages. Each new retail package has state Productized
    ForSaleByGrower,        // 9   Bale and its retail packages are now for sale to distributor. 
    SoldByGrower,           // 10  Sold to distributor. The owner of the bale and its retail packages is now the Distributor
    ShippedToDistributor,   // 11  Shipped to retailer/dispensary
    ReceivedByDistributor,  // 12  Received by retailer/dispensary. 
    ForSaleByDistributor,   // 13  Bales and retail items now for sale to retailer
    SoldByDistributor,      // 14  Bales and retail items now sold to retailer. Owner is now the retailer
    ShippedToRetailer,      // 15  Shipped to retailer/dispensary
    ReceivedByRetailer,     // 16  Received by retailer/dispensary. 
    ForSaleByRetailer,      // 17  Retailer/dispensary puts individual package onto its shelves for sale
    PurchasedByConsumer     // 18  Consumer buys a retail package
  }

  struct FarmInfo {
      string  originFarmName; // Grower Name
      string  originFarmInformation;  // Grower Information
      string  originFarmLatitude; // Grow Latitude
      string  originFarmLongitude;  // Grow Longitude
  }

  struct BaleAddresses {
    address payable ownerID;  // Metamask-Ethereum address of the current owner as the product moves through various stages
    address payable originGrowerID; // Metamask-Ethereum address of the Grower/Farmer
    address payable growerID;  // Metamask-Ethereum address of the Grower
    address payable testerID;  // Metamask-Ethereum address of the Tester
    address payable distributorID;  // Metamask-Ethereum address of the Distributor
    address payable retailerID; // Metamask-Ethereum address of the Retailer

  }
  //  
  // Define a struct 'BaleItem'
  //  
  struct BaleItem {
    uint    sku;      // Stock Keeping Unit (SKU), generated automatically
    uint    upc;      // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    uint    baleId;   // ID unique to bale, set by grower
    string  strainName;
    uint    thcPct;
    uint    cbdPct;
    string  productNotes; // Product Notes
    uint    growerPrice; // Price charged by grower for distributor to buy bale
    uint    distributorPrice; // Price charged by distributor to retailer to buy bale 
    uint    numRetailProducts; // Number of retail products created for this bale (eg 10)
    State   itemState;  // Product State as represented in the enum above
    BaleAddresses baleAddresses;
  }

  //  
  // Define a struct 'SampleItem'. We only store testerID in addresses because the other addresses we can get from the bale.
  //  
  struct SampleItem {
    uint    upc;      // Universal Product Code (UPC), generated by the Grower/Farmer, goes on the package, can be verified by the Consumer
    uint    baleId;   // ID unique to bale, set by grower
    uint    sampleId; // ID unique to this sample for the given bale
    address payable ownerID;  // Metamask-Ethereum address of the current owner as the product moves through various stages
    State   itemState;  // Product State as represented in the enum above
    address payable testerID;  // Metamask-Ethereum address of the Tester
  }

  //  
  // Define a struct 'RetailItem'. We only store consumerID in addresses because the other addresses we can get from the bale.
  //  
  struct RetailItem {
    uint    sku;      // Stock Keeping Unit (SKU), generated automatically
    uint    upc;      // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    uint    baleId;   // ID unique to bale, set by grower
    uint    retailId; // ID unique to this retail package for the given bale
    uint    retailPrice; // Product Price for each retail item
    address payable ownerID;  // Metamask-Ethereum address of the current owner as the product moves through various stages
    State   itemState;  // Product State as represented in the enum above
    address payable consumerID; // Metamask-Ethereum address of the Consumer
  }

  //
  // mapping for info about growers
  //
  mapping (address => FarmInfo) farmsInfo;

  //
  // mappings for items
  //
  // store BaleItem by [upc][baleId]. 
  //
  mapping (uint => mapping(uint => BaleItem)) bales;

  //
  // store SampleItem by [upc][baleId][sampleId]
  //
  mapping (uint => mapping(uint => mapping(uint => SampleItem))) samples;
  mapping (uint => mapping(uint => SampleItem[])) samplesForBale;

  //
  // store RetailItem by [upc][baleId][retailId]
  //
  mapping (uint => mapping(uint => mapping(uint => RetailItem))) retailItems;
  mapping (uint => mapping(uint => RetailItem[])) retailItemsForBale;

  //
  // Define public mappings 'baleItemsHistory', 'sampleItemsHistory, 'retailItemsHistory'
  // that map the UPC and Ids to an array of TxHash, 
  // that track the item's journey through the supply chain -- to be sent from DApp.
  //
  mapping (uint => mapping(uint => string[])) baleItemsHistory;
  mapping (uint => mapping(uint => mapping(uint => string[]))) sampleItemsHistory;
  mapping (uint => mapping(uint => mapping(uint => string[]))) retailItemsHistory;
 
  mapping (uint => string) statesAsStrings;
  // 
  // Define 21 events: 19 events with the same 19 state values plus two creation events: SampleCreated and RetailItemCreated
  // 
  event Harvested(uint upc, uint baleId, uint _state, string _stateStr, string _strainStr);
  event Processed(uint upc, uint baleId, uint _state, string _stateStr);
  event Sampled(uint upc, uint baleId);
  event SampleCreated(uint upc, uint baleId, uint sampleId);
  event SampleRequested(uint upc, uint baleId, uint sampleId);
  event SentToTester(uint upc, uint baleId, uint sampleId);
  event ReceivedByTester(uint upc, uint baleId, uint sampleId);
  event InTesting(uint upc, uint baleId, uint sampleId);
  event Approved(uint upc, uint baleId, uint sampleId);
  event Productized(uint upc, uint baleId);
  event RetailItemCreated(uint upc, uint baleId, uint retailId);
  event ForSaleByGrower(uint upc, uint baleId, uint growerPrice);
  event SoldByGrower(uint upc, uint baleId);
  event ShippedToDistributor(uint upc, uint baleId);
  event ReceivedByDistributor(uint upc, uint baleId);
  event ForSaleByDistributor(uint upc, uint baleId, uint distributorPrice);
  event SoldByDistributor(uint upc, uint baleId);
  event ShippedToRetailer(uint upc, uint baleId);
  event ReceivedByRetailer(uint upc, uint baleId);
  event ForSaleByRetailer(uint upc, uint baleId, uint retailId, uint retailPrice);
  event PurchasedByConsumer(uint upc, uint baleId, uint retailId);

  /////////////////////////
  /////////////////////////
  // Define modifiers
  /////////////////////////
  /////////////////////////

  /////////////////////////////
  // price checking modifiers
  /////////////////////////////
  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address); 
    _;
  }

  // Define a modifer that verifies the distributor for shipping
  modifier verifyDistributor(uint _upc, uint _baleId, address _address) {
    require(bales[_upc][_baleId].baleAddresses.distributorID == _address); 
    _;
  }

  // Define a modifer that verifies the retailer for shipping or consumer purchase
  modifier verifyRetailer(uint _upc, uint _baleId, address _address) {
    require(bales[_upc][_baleId].baleAddresses.retailerID == _address); 
    _;
  }


  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  // Need a function version to get around stack too deep issue                 
  function paidEnoughFunc(uint _price) internal view {
    require(msg.value >= _price); 
  }

  
  // Define a modifier that checks the price and refunds the remaining balance to the buyer (the distributor buys bales from grower)
  modifier checkGrowerValue(uint _upc, uint baleId) {
    uint _price = bales[_upc][baleId].growerPrice;
    uint amountToReturn = msg.value - _price;
    bales[_upc][baleId].baleAddresses.distributorID.transfer(amountToReturn);
    _;
  }

  // Define a modifier that checks the price and refunds the remaining balance to the buyer (the retailer buys bales from distributor)
  modifier checkDistributorValue(uint _upc, uint baleId) {
    uint _price = bales[_upc][baleId].distributorPrice;
    uint amountToReturn = msg.value - _price;
    bales[_upc][baleId].baleAddresses.distributorID.transfer(amountToReturn);
    _;
  }

  // Define a modifier that checks the price and refunds the remaining balance to the buyer (the consumer buys retail items)
  modifier checkRetailerValue(uint _upc, uint baleId, uint retailId) {
    uint _price = retailItems[_upc][baleId][retailId].retailPrice;
    uint amountToReturn = msg.value - _price;
    retailItems[_upc][baleId][retailId].consumerID.transfer(amountToReturn);
    _;
  }

  // Need a function version to get around stack too deep issue                 
  function checkRetailerValueFunc(uint _upc, uint baleId, uint retailId) internal {
    uint _price = retailItems[_upc][baleId][retailId].retailPrice;
    uint amountToReturn = msg.value - _price;
    retailItems[_upc][baleId][retailId].consumerID.transfer(amountToReturn);
  }

  /////////////////////////////
  // state checking modifiers
  /////////////////////////////

  //
  // Define a modifier that checks if this bale exists at all yet 
  // In Solidity, accessing a mapping element will always return something (in this case a struct)
  // but if that element has not been written to (was not created in code) it will have values 0
  // (in this case all struct elements == 0)
  //
  // So, this bale will not exist if the sku is 0
  //
  modifier noSuchBale(uint _upc, uint baleId) {
    require(bales[_upc][baleId].sku == 0);
    _;
  }

  // Define a modifier that checks if a bale state is Harvested
  modifier harvested(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.Harvested);
    _;
  }

  // Define a modifier that checks if a bale state is Processed
  modifier processed(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.Processed);
    _;
  }
  
  // Define a modifier that checks if a bale state is Sampled
  modifier sampled(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.Sampled);
    _;
  }
  
  // Define a modifier that checks if a bale state is SampleRequested
  modifier sampleRequested(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.SampleRequested);
    _;
  }
  
  // Define a modifier that checks if the sample state is SentToTester
  modifier sentToTester(uint _upc, uint baleId, uint sampleId) {
    require(samples[_upc][baleId][sampleId].itemState == State.SentToTester);
    _;
  }

  // Define a modifier that checks if the sample state is ReceivedByTester
  modifier receivedByTester(uint _upc, uint baleId, uint sampleId) {
    require(samples[_upc][baleId][sampleId].itemState == State.ReceivedByTester);
    _;
  }

  // Define a modifier that checks if the sample state is InTesting  
  modifier inTesting(uint _upc, uint baleId, uint sampleId) {
    require(samples[_upc][baleId][sampleId].itemState == State.InTesting);
    _;
  }

  // Define a modifier that checks if the bale state is Approved  
  // Note: As soon as tester approves sample, the state of both the sample and the bale are set to Approved 
  modifier approved(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.Approved);
    _;
  }

  // Define a modifier that checks if the bale state is Productized
  modifier productized(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.Productized);
    _;
  }

  // Define a modifier that checks if the bale state is ForSaleByGrower
  modifier forSaleByGrower(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.ForSaleByGrower);
    _;
  }

  // Define a modifier that checks if the bale state is SoldByGrower
  modifier soldByGrower(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.SoldByGrower);
    _;
  }

  // Define a modifier that checks if the bale state is ShippedToDistributor
  modifier shippedToDistributor(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.ShippedToDistributor);
    _;
  }

  // Define a modifier that checks if the bale state is ReceivedByDistributor
  modifier receivedByDistributor(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.ReceivedByDistributor);
    _;
  }

  // Define a modifier that checks if the bale state is ForSaleByDistributor
  modifier forSaleByDistributor(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.ForSaleByDistributor);
    _;
  }

  // Define a modifier that checks if the bale state is SoldByDistributor
  modifier soldByDistributor(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.SoldByDistributor);
    _;
  }

  // Define a modifier that checks if the bale state is ShippedToRetailer
  modifier shippedToRetailer(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.ShippedToRetailer);
    _;
  }

  //
  // Define a modifier that checks if the bale state is ReceivedByRetailer
  // This is the final state of the bale
  //
  modifier receivedByRetailer(uint _upc, uint baleId) {
    require(bales[_upc][baleId].itemState == State.ReceivedByRetailer);
    _;
  }

  // Define a modifier that checks if the retail item state is ForSaleByRetailer
  modifier forSaleByRetailer(uint _upc, uint baleId, uint retailId) {
    require(retailItems[_upc][baleId][retailId].itemState == State.ForSaleByRetailer);
    _;
  }

  // Need a function version to get around stack too deep issue                 
  function forSaleByRetailerFunc(uint _upc, uint baleId, uint retailId) internal view {
    require(retailItems[_upc][baleId][retailId].itemState == State.ForSaleByRetailer);
  }

  // Define a modifier that checks if the retail item state is PurchasedByConsumer
  modifier purchasedByConsumer(uint _upc, uint baleId, uint retailId) {
    require(retailItems[_upc][baleId][retailId].itemState == State.PurchasedByConsumer);
    _;
  }

  //
  // In the constructor set 'autosku' to 1 and call fillStateDescriptions
  //
  constructor() public payable {
    autosku = 1;
    fillStateDescriptions(); 
  }

  // Define a function 'kill' if required
  function kill() onlyOwner public {
    selfdestruct(owner());
  }

  /////////////////////////////////////////////
  // cannabis specific functions
  /////////////////////////////////////////////
  function fillStateDescriptions() internal {
      statesAsStrings[uint(State.Harvested)] = "Harvested";
      statesAsStrings[uint(State.Processed)] = "Processed";
      statesAsStrings[uint(State.Sampled)]   = "Sampled";
      statesAsStrings[uint(State.SampleRequested)]   = "Sample Requested";
      statesAsStrings[uint(State.SentToTester)]   = "Sent To Tester";
      statesAsStrings[uint(State.ReceivedByTester)]   = "Received By Tester";
      statesAsStrings[uint(State.InTesting)]   = "In Testing";
      statesAsStrings[uint(State.Approved)]   = "Approved";
      statesAsStrings[uint(State.Productized)]   = "Productized";
      statesAsStrings[uint(State.ForSaleByGrower)]   = "For Sale By Grower";
      statesAsStrings[uint(State.SoldByGrower)]   = "Sold By Grower";
      statesAsStrings[uint(State.ShippedToDistributor)]   = "Shipped To Distributor";
      statesAsStrings[uint(State.ReceivedByDistributor)]   = "Received By Distributor";
      statesAsStrings[uint(State.ForSaleByDistributor)]   = "For Sale By Distributor";
      statesAsStrings[uint(State.SoldByDistributor)]   = "Sold By Distributor";
      statesAsStrings[uint(State.ShippedToRetailer)]   = "Shipped To Retailer";
      statesAsStrings[uint(State.ReceivedByRetailer)]   = "Received By Retailer";
      statesAsStrings[uint(State.ForSaleByRetailer)]   = "For Sale By Retailer";
      statesAsStrings[uint(State.PurchasedByConsumer)]   = "Purchased By Consumer";
  }

  function getStateString(State state) internal view returns (string memory) {
      return statesAsStrings[uint(state)];
  }

  function getStrainFromUPC(uint upc) internal pure returns (Strain) {
      uint s = upc % 10;
      if (s <= 2) {
          return Strain.TrippyPurpleBubblegumHaze;
      } else if (s <= 5) {
          return Strain.VulcanMindMelt;
      } else if (s <= 7) { 
          return Strain.CatatonicCouchlockKush;
      } else {
          return Strain.SnoozyWoozy;
      }
  }

  function getStrainString(Strain strain) internal pure returns (string memory) {
      if (strain == Strain.TrippyPurpleBubblegumHaze) {
          return "Trippy Purple Bubblegum Haze";  
      } else if (strain == Strain.VulcanMindMelt) {
          return "Vulcan Mind Melt";
      } else if (strain == Strain.CatatonicCouchlockKush) { 
          return "Catatonic Couchlock Kush";
      } else {
          return "Snoozy Woozy";
      }
  }

  function setMockTestResultsForStrain(uint upc) internal pure returns ( uint thcPct, uint cbdPct) {
      Strain strain = getStrainFromUPC(upc);
      if (strain == Strain.TrippyPurpleBubblegumHaze) {
          thcPct = 30;
          cbdPct = 1;
      } else if (strain == Strain.VulcanMindMelt) { 
          thcPct = 25;
          cbdPct = 2;
      } else if (strain == Strain.CatatonicCouchlockKush) { 
          thcPct = 20;
          cbdPct = 3;
      } else { 
          // SnoozyWoozy
          thcPct = 5;
          cbdPct = 20;
      }
  }

  ///////////////////////////////////
  // action functions
  ///////////////////////////////////

  // 
  // Define a function 'setGrowerInfo' that sets information aboutthe Farm/Grower 
  // 
  function addGrowerInfo(address _growerID, string memory _originFarmName, string memory _originFarmInformation, 
                       string memory _originFarmLatitude, string  memory _originFarmLongitude) public 
        onlyGrower()
  {
    FarmInfo memory farmInfo = FarmInfo({
      originFarmName: _originFarmName,
      originFarmInformation: _originFarmInformation,
      originFarmLatitude: _originFarmLatitude,
      originFarmLongitude: _originFarmLongitude
    });
    farmsInfo[_growerID] = farmInfo;
  }
  // 
  // Define a function 'harvestWeed' that allows a grower to mark a bale 'Harvested'
  // 
  function harvestWeed(uint _upc, uint _baleId, address payable _originGrowerID, string memory _productNotes) public 
        onlyGrower()
        noSuchBale(_upc,_baleId)
        returns (uint state, string memory stateStr, string memory strainStr)
  {
    Strain strain = getStrainFromUPC(_upc);
    strainStr = getStrainString(strain);
    //
    // Add the new item as part of Harvest
    //
    BaleAddresses memory baleAddresses = BaleAddresses({
      ownerID: _originGrowerID,
      originGrowerID: _originGrowerID,
      growerID: _originGrowerID,
      testerID: address(0),
      distributorID: address(0),
      retailerID: address(0)
    });
    bales[_upc][_baleId] = BaleItem({
      sku: autosku,
      upc: _upc,
      baleId: _baleId,
      strainName: strainStr,
      thcPct: 0,
      cbdPct: 0,
      productNotes: _productNotes,
      growerPrice: 0,
      distributorPrice: 0,
      numRetailProducts: 0,
      itemState: State.Harvested,
      baleAddresses: baleAddresses
    });

    // 
    // Increment sku
    // 
    autosku = autosku + 1;

    // Emit the appropriate event
    emit Harvested(_upc,_baleId,uint(State.Harvested), stateStr, strainStr);

    stateStr = getStateString(State.Harvested);
    return (uint(State.Harvested), stateStr, strainStr);
  }

  //
  // Define a function 'processtWeed' that allows a grower/farmer to mark an item 'Processed'
  //
  function processWeed(uint _upc, uint _baleId) public 
        onlyGrower() 
        harvested(_upc,_baleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.originGrowerID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.Processed;
    
    // Emit the appropriate event
    emit Processed(_upc,_baleId, uint(State.Processed), stateStr);

    stateStr = getStateString(State.Processed);
    return (uint(State.Processed), stateStr);
  }

  //
  // Define a function 'sampleWeed' that creates a sample for testing and allows a grower/farmer to mark bale as 'Sampled'
  //
  function sampleWeed(uint _upc, uint _baleId, address payable testerAddr) public 
        onlyGrower() 
        processed(_upc,_baleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.originGrowerID)
        returns (uint state, string memory stateStr, uint newSampleId)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].baleAddresses.testerID =  testerAddr;
    bales[_upc][_baleId].itemState = State.Sampled;
    
    newSampleId = 1;
    samples[_upc][_baleId][newSampleId] = SampleItem({
       upc: _upc,
       baleId: _baleId,
       sampleId: newSampleId,
       ownerID: bales[_upc][_baleId].baleAddresses.ownerID,
       itemState: State.Sampled,
       testerID: address(0)
    });
    samplesForBale[_upc][_baleId].push(samples[_upc][_baleId][newSampleId]);

    // Emit the appropriate event
    emit Sampled(_upc,_baleId);
    emit SampleCreated(_upc,_baleId,newSampleId);

    stateStr = getStateString(State.Sampled);
    return (uint(State.Sampled), stateStr, newSampleId);
  }

  //
  // Define a function 'requestSample' that let's the tester request a sample from the bale.
  // It basically just sets the address for the tester
  //
  function requestSample(uint _upc, uint _baleId) public 
        onlyTester() 
        sampled(_upc,_baleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.testerID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].baleAddresses.testerID = msg.sender;
    bales[_upc][_baleId].itemState = State.SampleRequested;
    uint sampleId = samplesForBale[_upc][_baleId][0].sampleId;
    samples[_upc][_baleId][sampleId].itemState = State.SampleRequested;
    samplesForBale[_upc][_baleId][0].itemState = State.SampleRequested;

    // Emit the appropriate event
    emit SampleRequested(_upc,_baleId,sampleId);

    stateStr = getStateString(State.SampleRequested);
    return (uint(State.SampleRequested), stateStr);
  } 

  //
  // Define a function 'sendSampleToTester' that let's the grower send the sample to the tester.
  //
  function sendSampleToTester(uint _upc, uint _baleId, uint _sampleId) public 
        onlyGrower() 
        sampleRequested(_upc,_baleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.originGrowerID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.SentToTester;
    samples[_upc][_baleId][_sampleId].itemState = State.SentToTester;   

    // Emit the appropriate event
    emit SentToTester(_upc,_baleId,_sampleId);

    stateStr = getStateString(State.SentToTester);
    return (uint(State.SentToTester), stateStr);
  } 

  //
  // Define a function 'receivedByTester' that let's the tester receive the sample.
  //
  function setReceivedByTester(uint _upc, uint _baleId, uint _sampleId) public 
        onlyTester() 
        sentToTester(_upc,_baleId,_sampleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.testerID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.ReceivedByTester;
    samples[_upc][_baleId][_sampleId].itemState = State.ReceivedByTester;   

    // Emit the appropriate event
    emit ReceivedByTester(_upc,_baleId,_sampleId);

    stateStr = getStateString(State.ReceivedByTester);
    return (uint(State.ReceivedByTester), stateStr);
  }
 
  //
  // Define a function 'testSample' that let's the tester start testing the sample  
  //
  function testSample(uint _upc, uint _baleId, uint _sampleId) public 
        onlyTester() 
        receivedByTester(_upc,_baleId,_sampleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.testerID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.InTesting;    
    samples[_upc][_baleId][_sampleId].itemState = State.InTesting;          

    // Emit the appropriate event
    emit InTesting(_upc,_baleId,_sampleId);

    stateStr = getStateString(State.InTesting);
    return (uint(State.InTesting), stateStr);

  } 

  //
  // Define a function 'approveSample' that let's the tester approve the sample and bale
  // It also uses (Mock) test results to set THC and CBD content
  //
  function approveSample(uint _upc, uint _baleId, uint _sampleId) public 
        onlyTester() 
        inTesting(_upc,_baleId,_sampleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.testerID)
        returns (uint state, string memory stateStr, uint thcPct, uint cbdPct)
  {
    (thcPct, cbdPct) = setMockTestResultsForStrain(_upc);

    // Update the appropriate fields
    samples[_upc][_baleId][_sampleId].itemState = State.Approved;
    bales[_upc][_baleId].thcPct = thcPct;        
    bales[_upc][_baleId].cbdPct = cbdPct;        
    bales[_upc][_baleId].itemState = State.Approved;

    // Emit the appropriate event
    emit Approved(_upc,_baleId,_sampleId);

    stateStr = getStateString(State.Approved);
    return (uint(State.Approved), stateStr, thcPct, cbdPct);
  } 

  //
  // Define a function 'productize' that allows a grower to create retail-sized packages from the bale
  // and mark an item 'Productized'
  //
  function productize(uint _upc, uint _baleId ) public 
        onlyGrower() 
        approved(_upc,_baleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.originGrowerID)
        returns (uint state, string memory stateStr, uint numRetailProducts)
  {
    //
    // create 10 retail sized units (yes in real life we would be creating many more!)
    //
    for (uint retailId = 1; retailId <=10; retailId++) {
        retailItems[_upc][_baleId][retailId] = RetailItem({
            sku: bales[_upc][_baleId].sku,
            upc: _upc,
            baleId: _baleId,
            retailId: retailId,
            retailPrice: 0,
            ownerID: bales[_upc][_baleId].baleAddresses.ownerID,
            itemState: State.Productized,
            consumerID: address(0)
         });
         retailItemsForBale[_upc][_baleId].push(retailItems[_upc][_baleId][retailId]);

         // Emit the appropriate creation event
         emit RetailItemCreated(_upc,_baleId,retailId);
    }
    // Update the appropriate fields
    numRetailProducts=10;
    bales[_upc][_baleId].numRetailProducts = numRetailProducts;
    bales[_upc][_baleId].itemState = State.Productized;
  
    // emit Productized event 
    emit Productized(_upc,_baleId);

    stateStr = getStateString(State.Productized);
    return (uint(State.Productized), stateStr, numRetailProducts);
  }

  //
  // Define a function 'setForSaleByGrower' that allows a grower to mark an item 'ForSaleByGrower'
  //
  function setForSaleByGrower(uint _upc, uint _baleId, uint _price) public 
        onlyGrower() 
        productized(_upc,_baleId) 
        verifyCaller(bales[_upc][_baleId].baleAddresses.originGrowerID)
        returns (uint state, string memory stateStr, uint growerPrice)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.ForSaleByGrower;
    growerPrice = _price;
    bales[_upc][_baleId].growerPrice = growerPrice;
    
    // Emit the appropriate event
    emit ForSaleByGrower(_upc,_baleId, growerPrice);

    stateStr = getStateString(State.ForSaleByGrower);
    return (uint(State.ForSaleByGrower), stateStr, growerPrice);
  }

  //
  // Define a function 'buyBaleFromGrower' that allows the distributor to mark an item 'SoldByGrower'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  //
  function buyBaleFromGrower(uint _upc, uint _baleId) public payable
        onlyDistributor() 
        forSaleByGrower(_upc,_baleId)
        paidEnough(bales[_upc][_baleId].growerPrice)
        checkGrowerValue(_upc,_baleId)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields - ownerID, distributorID, itemState
    bales[_upc][_baleId].baleAddresses.ownerID = msg.sender;
    bales[_upc][_baleId].baleAddresses.distributorID = msg.sender;
    bales[_upc][_baleId].itemState = State.SoldByGrower;
    
    // Transfer money to grower
    bales[_upc][_baleId].baleAddresses.originGrowerID.transfer(bales[_upc][_baleId].growerPrice);
    
    // emit the appropriate event
    emit SoldByGrower(_upc,_baleId);

    stateStr = getStateString(State.SoldByGrower);
    return (uint(State.SoldByGrower), stateStr);
  }

  //
  // Define a function 'shipToDistributor' that allows the distributor to mark an item 'Shipped'
  // Use the above modifers to check if the item is sold
  //
  function shipToDistributor(uint _upc, uint _baleId) public 
        onlyGrower()
        soldByGrower(_upc,_baleId)
        verifyCaller(bales[_upc][_baleId].baleAddresses.originGrowerID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.ShippedToDistributor;
    
    // Emit the appropriate event
    emit ShippedToDistributor(_upc,_baleId);

    stateStr = getStateString(State.ShippedToDistributor);
    return (uint(State.ShippedToDistributor), stateStr);
  }

  //
  // Define a function 'receivedByDistributor' that allows the distributor to mark an item 'ReceivedByDistributor'
  // Use the above modifers to check if the item is shipped
  //
  function setReceivedByDistributor(uint _upc, uint _baleId) public 
        onlyDistributor()
        shippedToDistributor(_upc,_baleId)
        verifyCaller(bales[_upc][_baleId].baleAddresses.distributorID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.ReceivedByDistributor;
    
    // Emit the appropriate event
    emit ReceivedByDistributor(_upc,_baleId);

    stateStr = getStateString(State.ReceivedByDistributor);
    return (uint(State.ReceivedByDistributor), stateStr);
  }

  //
  // Define a function 'setForSaleByDistributor' that allows a distributor to mark an item 'ForSaleByDistributor'
  //
  function setForSaleByDistributor(uint _upc, uint _baleId, uint _distributorPrice) public 
        onlyDistributor()
        receivedByDistributor(_upc,_baleId)
        verifyCaller(bales[_upc][_baleId].baleAddresses.distributorID)
        returns (uint state, string memory stateStr, uint distributorPrice)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.ForSaleByDistributor;
    distributorPrice = _distributorPrice;
    bales[_upc][_baleId].distributorPrice = distributorPrice;
    
    // Emit the appropriate event
    emit ForSaleByDistributor(_upc,_baleId, distributorPrice);

    stateStr = getStateString(State.ForSaleByDistributor);
    return (uint(State.ForSaleByDistributor), stateStr, distributorPrice);
  }

  //
  // Define a function 'buyBaleFromDistributor' that allows the distributor to mark an item 'SoldByDistributor'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  //
  function buyBaleFromDistributor(uint _upc, uint _baleId) public payable
        onlyRetailer() 
        forSaleByDistributor(_upc,_baleId)
        paidEnough(bales[_upc][_baleId].distributorPrice)
        checkDistributorValue(_upc,_baleId)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields - ownerID, retailerID, itemState
    bales[_upc][_baleId].baleAddresses.ownerID = msg.sender;
    bales[_upc][_baleId].baleAddresses.retailerID = msg.sender;
    bales[_upc][_baleId].itemState = State.SoldByDistributor;
    
    // Transfer money to distributor
    bales[_upc][_baleId].baleAddresses.distributorID.transfer(bales[_upc][_baleId].distributorPrice);
    
    // emit the appropriate event
    emit SoldByDistributor(_upc,_baleId);

    stateStr = getStateString(State.SoldByDistributor);
    return (uint(State.SoldByDistributor), stateStr);
  }

  //
  // Define a function 'shipToRetailer' that allows the distributor to mark an item 'ShippedToRetailer'
  // Use the above modifers to check if the item is sold
  //
  function shipToRetailer(uint _upc, uint _baleId) public 
        onlyDistributor()
        soldByDistributor(_upc,_baleId)
        verifyCaller(bales[_upc][_baleId].baleAddresses.distributorID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.ShippedToRetailer;
    
    // Emit the appropriate event
    emit ShippedToRetailer(_upc,_baleId);

    stateStr = getStateString(State.ShippedToRetailer);
    return (uint(State.ShippedToRetailer), stateStr);
  }

  //
  // Define a function 'receivedByRetailer' that allows the retailer to mark an item 'ReceivedByRetailer'
  // Use the above modifers to check if the item is shipped
  //
  function setReceivedByRetailer(uint _upc, uint _baleId) public 
        onlyRetailer()
        shippedToRetailer(_upc,_baleId)
        verifyCaller(bales[_upc][_baleId].baleAddresses.retailerID)
        returns (uint state, string memory stateStr)
  {
    // Update the appropriate fields
    bales[_upc][_baleId].itemState = State.ReceivedByRetailer;
    
    // Emit the appropriate event
    emit ReceivedByRetailer(_upc,_baleId);

    stateStr = getStateString(State.ReceivedByRetailer);
    return (uint(State.ReceivedByRetailer), stateStr);
  }

  //
  // Define a function 'setForSaleByRetailer' that allows a distributor to mark the retail items as 'ForSaleByRetailer'
  //
  function setForSaleByRetailer(uint _upc, uint _baleId, uint _retailPrice) public 
        onlyRetailer()
        receivedByRetailer(_upc,_baleId)
        verifyCaller(bales[_upc][_baleId].baleAddresses.retailerID)
        returns (uint state, string memory stateStr, uint retailPrice)
  {
    //
    // set retail price for each item
    // Apply markup percentage to bale price and divide by number of retail products to get retail price of each retail product
    //
    uint retailId;
    uint n = bales[_upc][_baleId].numRetailProducts;
    retailPrice = _retailPrice;

    //
    // Update the appropriate fields on the retail items for this bale
    //
    for (uint i = 0; i<n; i++) {
        retailId = retailItemsForBale[_upc][_baleId][i].retailId;
        retailItems[_upc][_baleId][retailId].retailPrice = retailPrice;
        retailItems[_upc][_baleId][retailId].itemState = State.ForSaleByRetailer;
    
        // Emit the appropriate event
        emit ForSaleByRetailer(_upc,_baleId,retailId, retailPrice);
    }

    bales[_upc][_baleId].itemState = State.ForSaleByRetailer;

    stateStr = getStateString(State.ForSaleByRetailer);
    return (uint(State.ForSaleByRetailer), stateStr, retailPrice);
  }

  //
  // Define a function 'purchaseRetailItem' that allows the consumer to mark an item 'PurchasedByConsumer'
  // NOTE: We use function versions of modifiers to avoid stack too deep error
  //
  function purchaseItem(uint _upc, uint _baleId, uint _retailId) public  payable
        onlyConsumer()
        returns (uint state, string memory stateStr)
  {
    //
    // modifier function checks
    //
    forSaleByRetailerFunc(_upc,_baleId,_retailId);
    paidEnoughFunc(retailItems[_upc][_baleId][_retailId].retailPrice);
    checkRetailerValueFunc(_upc,_baleId,_retailId);

    // Update the appropriate fields - ownerID, retailerID, itemState
    retailItems[_upc][_baleId][_retailId].ownerID = msg.sender;
    retailItems[_upc][_baleId][_retailId].consumerID = msg.sender;
    retailItems[_upc][_baleId][_retailId].itemState = State.PurchasedByConsumer;
    
    // Transfer money to retailer
    bales[_upc][_baleId].baleAddresses.retailerID.transfer(retailItems[_upc][_baleId][_retailId].retailPrice);
    
    // emit the appropriate event
    emit PurchasedByConsumer(_upc,_baleId,_retailId);

    stateStr = getStateString(State.ForSaleByRetailer);
    return (uint(State.ForSaleByRetailer), stateStr);
  }


//////////


}
