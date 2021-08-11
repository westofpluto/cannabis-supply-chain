App = {
    web3Provider: null,
    contracts: {},
    emptyAddress: "0x0000000000000000000000000000000000000000",
    sku: 0,
    upc: 0,
    baleId: 0,
    sampleId: 1,
    retailId: 0,
    prevmetamaskAccountID: "",
    metamaskAccountID: "0x0000000000000000000000000000000000000000",
    ownerID: "0x0000000000000000000000000000000000000000",
    originGrowerID: "0x0000000000000000000000000000000000000000",
    originFarmName: null,
    originFarmInformation: null,
    originFarmLatitude: null,
    originFarmLongitude: null,
    productNotes: null,
    strainName: null,
    thcPct: 0,
    cbdPct: 0,
    stateStr: null,
    growerPrice: 0,
    growerPriceWei: 0,
    distributorPrice: 0,
    distributorPriceWei: 0,
    retailPrice: 0,
    retailPriceWei: 0,
    testerID: "0x0000000000000000000000000000000000000000",
    distributorID: "0x0000000000000000000000000000000000000000",
    retailerID: "0x0000000000000000000000000000000000000000",
    consumerID: "0x0000000000000000000000000000000000000000",
    numRetailProducts: 0,

    init: async function () {
        App.showHideRetail(false);
        App.readForm();
        /// Setup access to blockchain
        return await App.initWeb3();
    },

    readForm: function () {
        App.upc = $("#upc").val();
        App.baleId = $("#upc").val();
        App.ownerID = $("#ownerID").val();
        App.originGrowerID = $("#originGrowerID").val();
        App.originFarmName = $("#originFarmName").val();
        App.originFarmInformation = $("#originFarmInformation").val();
        App.originFarmLatitude = $("#originFarmLatitude").val();
        App.originFarmLongitude = $("#originFarmLongitude").val();
        App.productNotes = $("#productNotes").val();
        App.strainName = $("#strainname").val();
        App.thcPct = $("#thcpct").val();
        App.cbdPct = $("#cbdpct").val();
        App.growerPrice = $("#growerprice").val();
        App.distributorPrice = $("#distributorprice").val();
        App.testerID = $("#testerID").val();
        App.distributorID = $("#distributorID").val();
        App.retailPrice = $("#retailprice").val();
        App.retailerID = $("#retailerID").val();
        App.consumerID = $("#consumerID").val();

        console.log(
            App.sku,
            App.upc,
            App.baleId,
            App.ownerID, 
            App.originGrowerID, 
            App.originFarmName, 
            App.originFarmInformation, 
            App.originFarmLatitude, 
            App.originFarmLongitude, 
            App.productNotes, 
            App.strainName,
            App.thcPct,
            App.cbdPct,
            App.growerPrice, 
            App.distributorPrice, 
            App.retailPrice, 
            App.testerID, 
            App.distributorID, 
            App.retailerID, 
            App.consumerID
        );
    },

    milliEthToWei: function(x) {
        return x*1000000000000000;
    },

    weiToMilliEth: function(x) {
        return x/1000000000000000;
    },


    initWeb3: async function () {
        /// Find or Inject Web3 Provider
        /// Modern dapp browsers...
        if (window.ethereum) {
            App.web3Provider = window.ethereum;
            try {
                // Request account access
                await window.ethereum.enable();
            } catch (error) {
                // User denied account access...
                console.error("User denied account access")
            }
        }
        // Legacy dapp browsers...
        else if (window.web3) {
            App.web3Provider = window.web3.currentProvider;
        }
        // If no injected web3 instance is detected, fall back to Ganache
        else {
            App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
        }

        App.getMetaskAccountID();

        return App.initSupplyChain();
    },

    getMetaskAccountID: function () {
        web3 = new Web3(App.web3Provider);

        // Retrieving accounts
        web3.eth.getAccounts(function(err, res) {
            if (err) {
                console.log('Error:',err);
                return;
            }
            console.log('In getMetaskAccountID, getMetaskID:',res);
            App.metamaskAccountID = res[0];
            console.log('In getMetaskAccountID, App.metamaskAccountID :',App.metamaskAccountID);

        })

    },

    initSupplyChain: function () {
        /// Source the truffle compiled smart contracts
        var jsonSupplyChain='../../build/contracts/SupplyChain.json';
    
        web3 = new Web3(App.web3Provider);
        web3.eth.defaultAccount = web3.eth.accounts[0];    

        /// JSONfy the smart contracts
        $.getJSON(jsonSupplyChain, function(data) {
            console.log('data',data);
            var SupplyChainArtifact = data;
            App.contracts.SupplyChain = TruffleContract(SupplyChainArtifact);
            App.contracts.SupplyChain.setProvider(App.web3Provider);
            
            //App.fetchItemBufferOne();
            //App.fetchItemBufferTwo();
            App.fetchEvents();

        });

        return App.bindEvents();
    },

    bindEvents: function() {
        $(document).on('click', App.handleButtonClick);
    },

    handleButtonClick: async function(event) {
        event.preventDefault();

        App.getMetaskAccountID();

        let btnId = $(event.target).data('id');
        console.log('btnId',btnId);
        let retailId = 0;

        switch(btnId) {
            case "addgrower":
                return await App.addGrower(event);
                break;
            case "addgrowerinfo":
                return await App.addGrowerInfo(event);
                break;
            case "addtester":
                return await App.addTester(event);
                break;
            case "adddistributor":
                return await App.addDistributor(event);
                break;
            case "addretailer":
                return await App.addRetailer(event);
                break;
            case "addconsumer":
                return await App.addConsumer(event);
                break;
            case "Set Metamask Account":
                return await App.addGrower(event);
                break;
            case "harvest":
                return await App.harvestWeed(event);
                break;
            case "process":
                return await App.processWeed(event);
                break;
            case "sample":
                return await App.sampleWeed(event);
                break;
            case "requestsample":
                return await App.requestSample(event);
                break;
            case "sendsample":
                return await App.sendSampleToTester(event);
                break;
            case "setrecvtester":
                return await App.setReceivedByTester(event);
                break;
            case "testsample":
                return await App.testSample(event);
                break;
            case "setapprove":
                return await App.approveSample(event);
                break;
            case "productize":
                return await App.productize(event);
                break;
            case "setforsalegrower":
                return await App.setForSaleByGrower(event);
                break;
            case "buybalefromgrower":
                return await App.buyBaleFromGrower(event);
                break;
            case "shiptodistrib":
                return await App.shipToDistributor(event);
                break;
            case "setrecvdistrib":
                return await App.setReceivedByDistributor(event);
                break;
            case "setforsalebydistrib":
                return await App.setForSaleByDistributor(event);
                break;
            case "buybalefromdistrib":
                return await App.buyBaleFromDistributor(event);
                break;
            case "shiptoretailer":
                return await App.shipToRetailer(event);
                break;
            case "setrecvretailer":
                return await App.setReceivedByRetailer(event);
                break;
            case "setforsaleretailer":
                return await App.setForSaleByRetailer(event);
                break;
            case "fetchbaleinfo":
                return await App.fetchBaleInfo(event);
                break;
            case "fetchbaleaddrinfo":
                return await App.fetchBaleAddressInfo(event);
                break;
            case "fetchretailids":
                return await App.fetchBaleRetailIds(event);
                break;
            case "fetchretailitem":
                return await App.fetchRetailItemInfo(event);
                break;
            case "buyjar1":
                return await App.purchaseItem(event,1);
                break;
            case "buyjar2":
                return await App.purchaseItem(event,2);
                break;
            case "buyjar3":
                return await App.purchaseItem(event,3);
                break;
            case "buyjar4":
                return await App.purchaseItem(event,4);
                break;
            case "buyjar5":
                return await App.purchaseItem(event,5);
                break;
            case "buyjar6":
                return await App.purchaseItem(event,6);
                break;
            case "buyjar7":
                return await App.purchaseItem(event,7);
                break;
            case "buyjar8":
                return await App.purchaseItem(event,8);
                break;
            case "buyjar9":
                return await App.purchaseItem(event,9);
                break;
            case "buyjar10":
                return await App.purchaseItem(event,10);
                break;
            }
    },

    addGrower: function(event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        let _originGrowerID = $("#originGrowerID").val();

        App.contracts.SupplyChain.deployed().then(function(instance) {
            console.log("Calling addGrower("+_originGrowerID+");");
            return instance.addGrower(_originGrowerID, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('addGrower has valid result');
            console.log('addGrower',result);
            $("#originGrowerID").val(_originGrowerID);
            App.originGrowerID = _originGrowerID;
        }).catch(function(err) {
            console.log('addGrower threw an error');
            console.log(err.message);
        });
    },

    addGrowerInfo: function(event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        let _growerID = App.metamaskAccountID;
        let _originFarmName =  $("#originFarmName").val();
        let _originFarmInformation = $("#originFarmInformation").val();
        let _originFarmLatitude = $("#originFarmLatitude").val();
        let _originFarmLongitude = $("#originFarmLongitude").val();

        App.contracts.SupplyChain.deployed().then(function(instance) {
            console.log("Calling addGrowerInfo");
            console.log("  _growerID = "+_growerID);
            console.log("  _originFarmName = "+_originFarmName);
            console.log("  _originFarmInformation = "+_originFarmInformation);
            console.log("  _originFarmLatitude = "+_originFarmLatitude);
            console.log("  _originFarmLongitude = "+_originFarmLongitude);
            console.log("  _App.metamaskAccountID = "+App.metamaskAccountID);
            return instance.addGrowerInfo(_growerID,
                App.originFarmName,
                App.originFarmInformation,
                App.originFarmLatitude,
                App.originFarmLongitude, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('addGrowerInfo',result);
            $("#originFarmName").val(_originFarmName);
            $("#originFarmInformation").val(_originFarmInformation);
            $("#originFarmLatitude").val(_originFarmLatitude);
            $("#originFarmLongitude").val(_originFarmLongitude);
            App.originFarmName = _originFarmName;
            App.originFarmInformation = _originFarmInformation;
            App.originFarmLatitude = _originFarmLatitude;
            App.originFarmLongitude = _originFarmLongitude;
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    addTester: function(event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        let _testerID = $("#testerID").val();

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.addTester(_testerID,{from: App.metamaskAccountID});
        }).then(function(result) {
            $("#testerID").val(_testerID);
            App.testerID = _testerID;
            console.log('addTester',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    addDistributor: function(event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        let _distributorID = $("#distributorID").val();

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.addDistributor(_distributorID, {from: App.metamaskAccountID});
        }).then(function(result) {
            $("#distributorID").val(_distributorID);
            App.distributorID = _distributorID;
            console.log('addDistributor',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    addRetailer: function(event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        let _retailerID = $("#retailerID").val();

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.addRetailer(_retailerID, {from: App.metamaskAccountID});
        }).then(function(result) {
            $("#retailerID").val(_retailerID);
            App.retailerID = _retailerID;
            console.log('addRetailer',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    addConsumer: function(event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        let _consumerID = $("#consumerID").val();

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.addConsumer(_consumerID, {from: App.metamaskAccountID});
        }).then(function(result) {
            $("#consumerID").val(_consumerID);
            App.consumerID = _consumerID;
            console.log('addConsumer',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    harvestWeed: function(event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        console.log("Inside App.harvestWeed(event) ");

        App.contracts.SupplyChain.deployed().then(function(instance) {
            console.log("Calling harvestWeed...");
            App.productNotes = $("#productNotes").val();
            console.log("App.upc is ",App.upc);
            console.log("App.baleId is ",App.baleId);
            console.log("App.metamaskAccountID is ",App.metamaskAccountID);
            console.log("App.productNotes is ",App.productNotes);

            return instance.harvestWeed(
                App.upc, 
                App.baleId, 
                App.metamaskAccountID, 
                App.productNotes,
                {from: App.metamaskAccountID}
            );
        }).then(function(result) {
            console.log('harvestWeed',result);
            $("#ownerID").val(App.originGrowerID);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    processWeed: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.processWeed(App.upc, App.baleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('processWeed',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    sampleWeed: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.sampleWeed(App.upc, App.baleId, App.testerID, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('sampleWeed',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    requestSample: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.requestSample(App.upc, App.baleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('requestSample',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    sendSampleToTester: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.sendSampleToTester(App.upc, App.baleId, App.sampleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('sendSampleToTester',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    setReceivedByTester: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.setReceivedByTester(App.upc, App.baleId, App.sampleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('setReceivedByTester',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
   
    testSample: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.testSample(App.upc, App.baleId, App.sampleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('testSample',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    approveSample: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.approveSample(App.upc, App.baleId, App.sampleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('approveSample',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    productize: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.productize(App.upc, App.baleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('productize',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    setForSaleByGrower: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        web3 = new Web3(App.web3Provider);

        web3 = new Web3(App.web3Provider);
        App.contracts.SupplyChain.deployed().then(function(instance) {
            App.growerPrice = $("#growerprice").val();
            App.growerPriceWei = App.milliEthToWei(App.growerPrice);
            return instance.setForSaleByGrower(App.upc, App.baleId, App.growerPriceWei, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('setForSaleByGrower',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    buyBaleFromGrower: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.buyBaleFromGrower(App.upc, App.baleId, 
                    {from: App.metamaskAccountID, value: App.growerPriceWei});
        }).then(function(result) {
            console.log('buyBaleFromGrower',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    shipToDistributor: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.shipToDistributor(App.upc, App.baleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('shipToDistributor',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    setReceivedByDistributor: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.setReceivedByDistributor(App.upc, App.baleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('setReceivedByDistributor',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    setForSaleByDistributor: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        web3 = new Web3(App.web3Provider);

        App.contracts.SupplyChain.deployed().then(function(instance) {
            App.distributorPrice = $("#distributorprice").val();  // in milliether
            App.distributorPriceWei = App.milliEthToWei(App.distributorPrice);
            return instance.setForSaleByDistributor(App.upc, App.baleId, App.distributorPriceWei, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('setForSaleByDistributor',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    buyBaleFromDistributor: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.buyBaleFromDistributor(App.upc, App.baleId, 
                  {from: App.metamaskAccountID, value: App.distributorPriceWei});
        }).then(function(result) {
            console.log('buyBaleFromDistributor',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    shipToRetailer: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.shipToRetailer(App.upc, App.baleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('shipToRetailer',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    setReceivedByRetailer: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));

        App.contracts.SupplyChain.deployed().then(function(instance) {
            return instance.setReceivedByRetailer(App.upc, App.baleId, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('setReceivedByRetailer',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    setForSaleByRetailer: function (event) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        web3 = new Web3(App.web3Provider);

        App.contracts.SupplyChain.deployed().then(function(instance) {
            App.retailPrice = $("#retailprice").val();
            App.retailPriceWei = App.milliEthToWei(App.retailPrice);
            return instance.setForSaleByRetailer(App.upc, App.baleId, App.retailPriceWei, {from: App.metamaskAccountID});
        }).then(function(result) {
            console.log('setForSaleByRetailer',result);
        }).catch(function(err) {
            console.log(err.message);
        });
    },
    
    purchaseItem: function (event, rid) {
        event.preventDefault();
        var processId = parseInt($(event.target).data('id'));
        console.log('Inside purchaseItem ',rid);
        console.log('App.retailPriceWei is ',App.retailPriceWei);

        App.contracts.SupplyChain.deployed().then(function(instance) {
            App.retailId = rid;
            return instance.purchaseItem(App.upc, App.baleId, App.retailId, 
                  {from: App.metamaskAccountID, value: App.retailPriceWei});
        }).then(function(result) {
            console.log('purchaseItem',result);
            App.disableRetailButton(rid);
            console.log('afterDisableRetailButton');
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    fetchBaleInfo: function (event) {
        event.preventDefault();


        App.upc = $('#upc').val();
        App.baleId = $('#baleId').val();
        console.log('upc ',App.upc,', baleId ',App.baleId);

        App.contracts.SupplyChain.deployed().then(function(instance) {
          return instance.fetchBaleInfo.call(App.upc,App.baleId);
        }).then(function(result) {
          const _itemSKU = result[0].toNumber();
          const _strainName = result[1];
          const _thcPct = result[2].toNumber();
          const _cbdPct = result[3].toNumber();
          const _productNotes = result[4];
          const _growerPrice=result[5].toNumber();
          const _distributorPrice=result[6].toNumber();
          const _numRetail=result[7].toNumber();
          const _ownerAddr=result[8];
          const _stateStr=result[9];

          console.log("  _itemSKU is ",_itemSKU);
          console.log("  _strainName is ",_strainName);
          console.log("  _thcPct is ",_thcPct);
          console.log("  _cbdPct is ",_cbdPct);
          console.log("  _productNotes is ",_productNotes);
          console.log("  _growerPrice is ",_growerPrice);
          console.log("  _distributorPrice is ",_distributorPrice);
          console.log("  _numRetail is ",_numRetail);
          console.log("  _ownerAddr is ",_ownerAddr);
          console.log("  _stateStr is ",_stateStr);

          web3 = new Web3(App.web3Provider);
          App.sku = _itemSKU;
          App.strainName = _strainName;
          App.thcPct = _thcPct;    
          App.cbdPct = _cbdPct;    
          App.productNotes = _productNotes;    
          App.growerPriceWei = _growerPrice; 
          App.growerPrice = App.weiToMilliEth(App.growerPriceWei);
          console.log("  App.growerPriceWei is ",App.growerPriceWei);
          console.log("  App.growerPrice is ",App.growerPrice);
          App.distributorPriceWei = _distributorPrice; 
          App.distributorPrice = App.weiToMilliEth(App.distributorPriceWei);
          console.log("  App.distributorPriceWei is ",App.distributorPriceWei);
          console.log("  App.distributorPrice is ",App.distributorPrice);
          App.numRetailProducts = _numRetail;
          App.ownerID = _ownerAddr;
          App.stateStr = _stateStr;

          $("#sku").val(""+App.sku);
          $("#strainname").val(App.strainName);
          $("#thcpct").val(""+App.thcPct);
          $("#cbdpct").val(""+App.cbdPct);
          $("#growerprice").val(""+App.growerPrice);
          $("#distributorprice").val(""+App.distributorPrice);
          $("#productNotes").val(""+App.productNotes);
          $("#ownerID").val(""+App.ownerID);
          $("#numretailproducts").val(""+App.numRetailProducts);

          $("#balestate").val(App.stateStr);

          if (App.numRetailProducts > 0) {
                App.showHideRetail(true);
                App.enableRetailButtons();
          }
        }).catch(function(err) {

        }).catch(function(err) {
          console.log(err.message);
        });
    },

    fetchBaleAddressInfo: function () {
        App.upc = $('#upc').val();
        App.baleId = $('#baleId').val();
        console.log('fetchBaleAddressInfo: upc ',App.upc,', baleId ',App.baleId);

        App.contracts.SupplyChain.deployed().then(function(instance) {
          return instance.fetchBaleAddressInfo.call(App.upc,App.baleId);
        }).then(function(result) {
          console.log("fetchBaleAddressInfo result is ",result);
          const {0: _ownerID, 
                 1: _originGrowerID,
                 2: _testerID,
                 3: _distributorID,
                 4: _retailerID} = result;
          $("#ownerID").val(_ownerID);
        }).catch(function(err) {
          console.log(err.message);
        });
    },

    fetchBaleRetailIds: function () {
        App.upc = $('#upc').val();
        App.baleId = $('#baleId').val();
        console.log('upc ',App.upc,', baleId ',App.baleId);

        App.contracts.SupplyChain.deployed().then(function(instance) {
          return instance.fetchBaleRetailIds(App.upc,App.baleId);
        }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('fetchBaleRetailIds', result);
        }).catch(function(err) {
          console.log(err.message);
        });
    },

    fetchRetailItemInfo: function () {
        event.preventDefault();
        App.retailId = parseInt($(event.target).data('retailid'));
        console.log('retailId',retailId);

        App.upc = $('#upc').val();
        App.baleId = $('#baleId').val();
        console.log('upc ',App.upc,', baleId ',App.baleId);

        App.contracts.SupplyChain.deployed().then(function(instance) {
          return instance.fetchRetailItemInfo(App.upc,App.baleId,App.retailId);
        }).then(function(result) {
          console.log('fetchRetailItemInfo', result);
        }).catch(function(err) {
          console.log(err.message);
        });
    },

    fetchEvents: function () {
        if (typeof App.contracts.SupplyChain.currentProvider.sendAsync !== "function") {
            App.contracts.SupplyChain.currentProvider.sendAsync = function () {
                return App.contracts.SupplyChain.currentProvider.send.apply(
                App.contracts.SupplyChain.currentProvider,
                    arguments
              );
            };
        }

        App.contracts.SupplyChain.deployed().then(function(instance) {
        var events = instance.allEvents(function(err, log){
          if (!err)
            $("#ftc-events").append('<li>' + log.event + ' - ' + log.transactionHash + '</li>');
        });
        }).catch(function(err) {
          console.log(err.message);
        });
        
    },

    showHideRetail: function (showcmd) {
      let retaildiv = document.getElementById("retaildiv");
      if (showcmd == true) {
        retaildiv.style.display = "block";
      } else {
        retaildiv.style.display = "none";
      }
    },

    disableRetailButton: function ( rid ) {
        let btnid="buyjar"+rid;
        document.getElementById(btnid).disabled = true;
        document.getElementById(btnid).innerText = "Sold";
    },

    enableRetailButton: function ( rid ) {
        let btnid="buyjar"+rid;
        document.getElementById(btnid).disabled = false;
    },

    disableRetailButtons: function () {
        document.getElementById("buyjar1").disabled = true;
        document.getElementById("buyjar2").disabled = true;
        document.getElementById("buyjar3").disabled = true;
        document.getElementById("buyjar4").disabled = true;
        document.getElementById("buyjar5").disabled = true;
        document.getElementById("buyjar6").disabled = true;
        document.getElementById("buyjar7").disabled = true;
        document.getElementById("buyjar8").disabled = true;
        document.getElementById("buyjar9").disabled = true;
        document.getElementById("buyjar10").disabled = true;
    },

    enableRetailButtons: function () {
        document.getElementById("buyjar1").disabled = false;
        document.getElementById("buyjar1").innerText = "Purchase";
        document.getElementById("buyjar2").disabled = false;
        document.getElementById("buyjar2").innerText = "Purchase";
        document.getElementById("buyjar3").disabled = false;
        document.getElementById("buyjar3").innerText = "Purchase";
        document.getElementById("buyjar4").disabled = false;
        document.getElementById("buyjar4").innerText = "Purchase";
        document.getElementById("buyjar5").disabled = false;
        document.getElementById("buyjar5").innerText = "Purchase";
        document.getElementById("buyjar6").disabled = false;
        document.getElementById("buyjar6").innerText = "Purchase";
        document.getElementById("buyjar7").disabled = false;
        document.getElementById("buyjar7").innerText = "Purchase";
        document.getElementById("buyjar8").disabled = false;
        document.getElementById("buyjar8").innerText = "Purchase";
        document.getElementById("buyjar9").disabled = false;
        document.getElementById("buyjar9").innerText = "Purchase";
        document.getElementById("buyjar10").disabled = false;
        document.getElementById("buyjar10").innerText = "Purchase";
    }

};

$(function () {
    $(window).load(function () {
        App.init();
    });
});
