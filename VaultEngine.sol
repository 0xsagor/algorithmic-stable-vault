// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Stablecoin.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IPriceFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

contract VaultEngine is ReentrancyGuard {
    Stablecoin public immutable stablecoin;
    IPriceFeed public immutable priceFeed;

    uint256 public constant LIQUIDATION_THRESHOLD = 150; // 150%
    uint256 public constant MIN_COLLATERAL_RATIO = 110;

    struct Vault {
        uint256 collateral; // ETH in wei
        uint256 debt;       // STBL minted
    }

    mapping(address => Vault) public vaults;

    event VaultUpdated(address indexed user, uint256 collateral, uint256 debt);
    event Liquidated(address indexed user, address indexed liquidator, uint256 amount);

    constructor(address _stablecoin, address _priceFeed) {
        stablecoin = Stablecoin(_stablecoin);
        priceFeed = IPriceFeed(_priceFeed);
    }

    function depositAndMint(uint256 _mintAmount) external payable nonReentrant {
        Vault storage vault = vaults[msg.sender];
        vault.collateral += msg.value;
        vault.debt += _mintAmount;

        _checkHealthFactor(msg.sender);
        stablecoin.mint(msg.sender, _mintAmount);
        
        emit VaultUpdated(msg.sender, vault.collateral, vault.debt);
    }

    function repayAndWithdraw(uint256 _repayAmount, uint256 _withdrawAmount) external nonReentrant {
        Vault storage vault = vaults[msg.sender];
        require(vault.collateral >= _withdrawAmount, "Insufficient collateral");
        
        if (_repayAmount > 0) {
            stablecoin.burn(msg.sender, _repayAmount);
            vault.debt -= _repayAmount;
        }
        
        vault.collateral -= _withdrawAmount;
        if (vault.debt > 0) {
            _checkHealthFactor(msg.sender);
        }

        payable(msg.sender).transfer(_withdrawAmount);
        emit VaultUpdated(msg.sender, vault.collateral, vault.debt);
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // Adjust to 18 decimals
    }

    function _checkHealthFactor(address user) internal view {
        Vault memory vault = vaults[user];
        uint256 ethPrice = getEthPrice();
        uint256 collateralValue = (vault.collateral * ethPrice) / 1e18;
        
        // (Collateral * 100) / Debt must be >= Threshold
        require((collateralValue * 100) / vault.debt >= LIQUIDATION_THRESHOLD, "Below health factor");
    }

    receive() external payable {}
}
