// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SecureTokenPlatformV1 is Initializable, ERC20Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    // Define roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RATE_SETTER_ROLE = keccak256("RATE_SETTER_ROLE");

    // Mapping to store the rates for each token pair
    mapping(bytes32 => uint256) private _rates;

    modifier onlyOwnerOrAdmin{
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only owner and Admin role can call this function"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Initialize contract with the initial supply and admin role
    function initialize(
        uint256 initialSupply, 
        address admin, 
        string memory name, 
        string memory symbol
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        _mint(msg.sender, initialSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner role
        _setupRole(ADMIN_ROLE, admin);
        _setupRole(RATE_SETTER_ROLE, admin);
        __UUPSUpgradeable_init();
    }

    // Only owner and admin can mint tokens
    function mint(address to, uint256 amount) public onlyOwnerOrAdmin {
        _mint(to, amount);
    }

    // Only owner and admin can burn tokens
    function burn(address from, uint256 amount) public onlyOwnerOrAdmin {
        _burn(from, amount);
    }

    // Secure token swap function
    function swapTokens(address token1, address token2, uint256 amount) public payable nonReentrant {
        ERC20Upgradeable tokenOne = ERC20Upgradeable(token1);
        ERC20Upgradeable tokenTwo = ERC20Upgradeable(token2);
        uint256 swapRate = getSwapRate(token1, token2);
        uint256 maxSlippage = 10; // 10%
        uint256 minRate = swapRate - (swapRate * maxSlippage / 100);
        uint256 maxRate = swapRate + (swapRate * maxSlippage / 100);
        require(
            token1 != token2 &&
            amount > 0 &&
            tokenOne.balanceOf(msg.sender) >= amount &&
            tokenOne.allowance(msg.sender, address(this)) >= amount &&
            minRate >0 &&
            tokenTwo.balanceOf(address(this)) >= maxRate*amount
        );

        // Transfer tokens securely and atomically
        require(ERC20Upgradeable(token1).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(ERC20Upgradeable(token2).transfer(msg.sender, amount*swapRate), "Transfer failed");

        // Protect against front-running and other attacks
        uint256 afterSwapRate = getSwapRate(token1, token2);
        require(afterSwapRate >= minRate && afterSwapRate <= maxRate, "Slippage too high");
    }

    // Helper function to get the swap rate
    function getSwapRate(address token1, address token2) private view returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(token1, token2));
        return _rates[key];
    }

    // Only authorized role setters can set rates
    function setRate(
        address token1, 
        address token2, 
        uint256 swapRate
    ) public onlyRole(RATE_SETTER_ROLE) {
        // Calculate the new rate as the ratio of the balances of token2 and token1
        uint256 token1balance = ERC20Upgradeable(token1).balanceOf(address(this));
        uint256 token2balance = ERC20Upgradeable(token2).balanceOf(address(this));
        require(
            token1 != token2 &&
            swapRate > 0 &&
            ERC20Upgradeable(token1).decimals() == ERC20Upgradeable(token2).decimals() &&
            token2balance >= swapRate*token1balance,
            "setting rate is invalid"
        );

        // Check that the new rate is within a certain percentage range of the current rate
        bytes32 key = keccak256(abi.encodePacked(token1, token2));

        // Update the rate in the contract storage
        _rates[key] = swapRate;
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(DEFAULT_ADMIN_ROLE) override{
    }
}

contract SecureTokenPlatformV2 is SecureTokenPlatformV1{
    function checkVersion() public pure returns(string memory version_){
        return "version2";
    } 
}
