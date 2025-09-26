/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title OrganicChain
 * @dev A smart contract for tracking organic food products from farm to consumer
 */
contract Project {
    
    // Struct to represent a product in the supply chain
    struct Product {
        uint256 id;
        string name;
        string origin;
        address farmer;
        uint256 harvestDate;
        bool isOrganic;
        uint256 currentPrice;
        address currentOwner;
        bool isAvailable;
        string[] certifications;
    }
    
    // Mapping to store products by their ID
    mapping(uint256 => Product) public products;
    
    // Mapping to track ownership history
    mapping(uint256 => address[]) public ownershipHistory;
    
    // Counter for product IDs
    uint256 private productCounter;
    
    // Events
    event ProductRegistered(uint256 indexed productId, string name, address indexed farmer);
    event ProductTransferred(uint256 indexed productId, address indexed from, address indexed to, uint256 price);
    event ProductVerified(uint256 indexed productId, string certification);
    
    // Modifiers
    modifier onlyProductOwner(uint256 _productId) {
        require(products[_productId].currentOwner == msg.sender, "Only product owner can perform this action");
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(_productId > 0 && _productId <= productCounter, "Product does not exist");
        _;
    }
    
    /**
     * @dev Register a new organic product
     * @param _name Name of the product
     * @param _origin Origin/location where product was grown
     * @param _harvestDate Timestamp of harvest
     * @param _price Initial price of the product
     * @param _certifications Array of certifications for the product
     */
    function registerProduct(
        string memory _name,
        string memory _origin,
        uint256 _harvestDate,
        uint256 _price,
        string[] memory _certifications
    ) public returns (uint256) {
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(bytes(_origin).length > 0, "Origin cannot be empty");
        require(_harvestDate <= block.timestamp, "Harvest date cannot be in the future");
        require(_price > 0, "Price must be greater than 0");
        
        productCounter++;
        
        Product storage newProduct = products[productCounter];
        newProduct.id = productCounter;
        newProduct.name = _name;
        newProduct.origin = _origin;
        newProduct.farmer = msg.sender;
        newProduct.harvestDate = _harvestDate;
        newProduct.isOrganic = true;
        newProduct.currentPrice = _price;
        newProduct.currentOwner = msg.sender;
        newProduct.isAvailable = true;
        newProduct.certifications = _certifications;
        
        // Initialize ownership history
        ownershipHistory[productCounter].push(msg.sender);
        
        emit ProductRegistered(productCounter, _name, msg.sender);
        
        return productCounter;
    }
    
    /**
     * @dev Transfer product ownership (buying/selling)
     * @param _productId ID of the product to transfer
     * @param _newOwner Address of the new owner
     */
    function transferProduct(uint256 _productId, address _newOwner) 
        public 
        payable 
        productExists(_productId) 
        onlyProductOwner(_productId) 
    {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        require(products[_productId].isAvailable, "Product is not available for transfer");
        require(msg.value >= products[_productId].currentPrice, "Insufficient payment");
        
        Product storage product = products[_productId];
        address previousOwner = product.currentOwner;
        
        // Update product ownership
        product.currentOwner = _newOwner;
        
        // Add to ownership history
        ownershipHistory[_productId].push(_newOwner);
        
        // Transfer payment to previous owner
        payable(previousOwner).transfer(product.currentPrice);
        
        // Return excess payment if any
        if (msg.value > product.currentPrice) {
            payable(msg.sender).transfer(msg.value - product.currentPrice);
        }
        
        emit ProductTransferred(_productId, previousOwner, _newOwner, product.currentPrice);
    }
    
    /**
     * @dev Verify product and add certification
     * @param _productId ID of the product to verify
     * @param _certification New certification to add
     */
    function verifyProduct(uint256 _productId, string memory _certification) 
        public 
        productExists(_productId) 
        onlyProductOwner(_productId) 
    {
        require(bytes(_certification).length > 0, "Certification cannot be empty");
        
        products[_productId].certifications.push(_certification);
        
        emit ProductVerified(_productId, _certification);
    }
    
    /**
     * @dev Get complete product information
     * @param _productId ID of the product
     */
    function getProduct(uint256 _productId) 
        public 
        view 
        productExists(_productId) 
        returns (
            uint256 id,
            string memory name,
            string memory origin,
            address farmer,
            uint256 harvestDate,
            bool isOrganic,
            uint256 currentPrice,
            address currentOwner,
            bool isAvailable,
            string[] memory certifications
        ) 
    {
        Product storage product = products[_productId];
        return (
            product.id,
            product.name,
            product.origin,
            product.farmer,
            product.harvestDate,
            product.isOrganic,
            product.currentPrice,
            product.currentOwner,
            product.isAvailable,
            product.certifications
        );
    }
    
    /**
     * @dev Get ownership history of a product
     * @param _productId ID of the product
     */
    function getOwnershipHistory(uint256 _productId) 
        public 
        view 
        productExists(_productId) 
        returns (address[] memory) 
    {
        return ownershipHistory[_productId];
    }
    
    /**
     * @dev Update product availability status
     * @param _productId ID of the product
     * @param _isAvailable New availability status
     */
    function updateAvailability(uint256 _productId, bool _isAvailable) 
        public 
        productExists(_productId) 
        onlyProductOwner(_productId) 
    {
        products[_productId].isAvailable = _isAvailable;
    }
    
    /**
     * @dev Update product price
     * @param _productId ID of the product
     * @param _newPrice New price for the product
     */
    function updatePrice(uint256 _productId, uint256 _newPrice) 
        public 
        productExists(_productId) 
        onlyProductOwner(_productId) 
    {
        require(_newPrice > 0, "Price must be greater than 0");
        products[_productId].currentPrice = _newPrice;
    }
    
    /**
     * @dev Get total number of registered products
     */
    function getTotalProducts() public view returns (uint256) {
        return productCounter;
    }
}
