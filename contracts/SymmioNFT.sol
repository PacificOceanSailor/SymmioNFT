// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract SymmioNFT is 
    ERC721Upgradeable, 
    ERC721BurnableUpgradeable, 
    AccessControlUpgradeable,
    PausableUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct NFTData {
        uint256 SYMMAmount;
        uint256 bonusAmount;
    }

    EnumerableSetUpgradeable.AddressSet private _whitelist;
    mapping(uint256 => NFTData) private _nftData;

    event Minted(address indexed to, uint256 tokenId, uint256 SYMMAmount, uint256 bonusAmount);
    event Burned(uint256 tokenId);
    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);
    event TransfersPaused();
    event TransfersUnpaused();

    modifier onlyWhitelisted() {
        require(_whitelist.contains(msg.sender), "Not whitelisted");
        _;
    }

    function initialize() public initializer {
        __ERC721_init("SymmioNFT", "SYMMIO");
        __ERC721Burnable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 SYMMAmount, uint256 bonusAmount) external onlyRole(ADMIN_ROLE){
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _nftData[tokenId] = NFTData({
            SYMMAmount: SYMMAmount,
            bonusAmount: bonusAmount
        });
        _tokenIdCounter.increment();
        emit Minted(to, tokenId, SYMMAmount, bonusAmount);
    }

    function burn(uint256 tokenId) public override {
        super.burn(tokenId);
        delete _nftData[tokenId];
        emit Burned(tokenId);
    }

    function pauseTransfers() external onlyRole(ADMIN_ROLE) {
        _pause();
        emit TransfersPaused();
    }

    function unpauseTransfers() external onlyRole(ADMIN_ROLE) {
        _unpause();
        emit TransfersUnpaused();
    }

    function addWhitelist(address account) external onlyRole(ADMIN_ROLE) {
        require(_whitelist.add(account), "Already whitelisted");
        emit WhitelistAdded(account);
    }

    function removeWhitelist(address account) external onlyRole(ADMIN_ROLE) {
        require(_whitelist.remove(account), "Not whitelisted");
        emit WhitelistRemoved(account);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist.contains(account);
    }

    function getSYMMAmount(uint256 tokenId) public view returns (uint256) {
        return _nftData[tokenId].SYMMAmount;
    }

    function getBonusAmount(uint256 tokenId) public view returns (uint256) {
        return _nftData[tokenId].bonusAmount;
    }

    function getTotalAmount(uint256 tokenId) public view returns (uint256) {
        return _nftData[tokenId].SYMMAmount + _nftData[tokenId].bonusAmount;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        require(!paused() || _whitelist.contains(to), "Transfers are paused");
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId); 
    }

}