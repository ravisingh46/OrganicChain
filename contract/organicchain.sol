// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title OrganicChain - Organic Food Supply Chain Tracker
 * @dev Smart contract for tracking organic food products through the supply chain
 */
contract Project {
    
    // Struct to represent an organic product
    struct Product {
        uint256 id;
        string name;
        address farmer;
        uint256 timestamp;
        string location;
        uint256 price;
        address currentOwner;
        bool isVerified;
        string[] certifications;
    }
    
    // State variables
    mapping(uint256 => Product) public products;
    mapping(address => bool) public verifiedFarmers;
    uint256 public productCounter;
    address public admin;
    
    // Events
    event ProductRegistered(uint256 indexed productId, string name, address farmer);
    event ProductTransferred(uint256 indexed productId, address from, address to, uint256 price);
    event FarmerVerified(address indexed farmer);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    modifier onlyVerifiedFarmer() {
        require(verifiedFarmers[msg.sender], "Only verified farmers can register products");
        _;
    }
    
    modifier onlyProductOwner(uint256 _productId) {
        require(products[_productId].currentOwner == msg.sender, "Only product owner can transfer");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        productCounter = 0;
    }
    
    /**
     * @dev Register a new organic product
     * @param _name Product name
     * @param _location Origin location
     * @param _price Product price in wei
     * @param _certifications Array of certification strings
     */
    function registerProduct(
        string memory _name,
        string memory _location,
        uint256 _price,
        string[] memory _certifications
    ) external onlyVerifiedFarmer {
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(_price > 0, "Price must be greater than zero");
        
        productCounter++;
        
        products[productCounter] = Product({
            id: productCounter,
            name: _name,
            farmer: msg.sender,
            timestamp: block.timestamp,
            location: _location,
            price: _price,
            currentOwner: msg.sender,
            isVerified: true,
            certifications: _certifications
        });
        
        emit ProductRegistered(productCounter, _name, msg.sender);
    }
    
    /**
     * @dev Transfer product ownership to another address
     * @param _productId ID of the product to transfer
     * @param _newOwner Address of the new owner
     * @param _newPrice New price for the product
     */
    function transferProduct(
        uint256 _productId,
        address _newOwner,
        uint256 _newPrice
    ) external onlyProductOwner(_productId) {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_productId > 0 && _productId <= productCounter, "Invalid product ID");
        require(_newPrice > 0, "New price must be greater than zero");
        
        address previousOwner = products[_productId].currentOwner;
        products[_productId].currentOwner = _newOwner;
        products[_productId].price = _newPrice;
        
        emit ProductTransferred(_productId, previousOwner, _newOwner, _newPrice);
    }
    
    /**
     * @dev Verify a farmer to allow them to register products
     * @param _farmer Address of the farmer to verify
     */
    function verifyFarmer(address _farmer) external onlyAdmin {
        require(_farmer != address(0), "Farmer address cannot be zero");
        require(!verifiedFarmers[_farmer], "Farmer is already verified");
        
        verifiedFarmers[_farmer] = true;
        emit FarmerVerified(_farmer);
    }
    
    // View functions
    function getProduct(uint256 _productId) external view returns (
        uint256 id,
        string memory name,
        address farmer,
        uint256 timestamp,
        string memory location,
        uint256 price,
        address currentOwner,
        bool isVerified
    ) {
        require(_productId > 0 && _productId <= productCounter, "Invalid product ID");
        Product memory product = products[_productId];
        return (
            product.id,
            product.name,
            product.farmer,
            product.timestamp,
            product.location,
            product.price,
            product.currentOwner,
            product.isVerified
        );
    }
    
    function getProductCertifications(uint256 _productId) external view returns (string[] memory) {
        require(_productId > 0 && _productId <= productCounter, "Invalid product ID");
        return products[_productId].certifications;
    }
    
    function getTotalProducts() external view returns (uint256) {
        return productCounter;
    }
    
    function isFarmerVerified(address _farmer) external view returns (bool) {
        return verifiedFarmers[_farmer];
    }
}
