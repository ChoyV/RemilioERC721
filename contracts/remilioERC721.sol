// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @title remilioERC721
 * @notice ERC721 based contract to build NFT collection with Blacklist function
 */
abstract contract remilioERC721 is ERC721 {
    using Strings for uint;

    // Errors
    error ERC721RemilioDoesntExist(uint tokenId);
    error ERC721RemilioNotAuthorized(address spender, uint tokenId);
    error ERC721RemilioBlacklisted(uint tokenId);
    error ERC721RemilioTransferToZeroAddress();
    error ERC721RemilioTransferFromIncorrectOwner();
    error ERC721RemilioInvalidSender();
    error ERC721RemilioInvalidReciever();
    error ERC721RemilioApprovalCallerNotOwner(address caller);

    // Events
    event AddedToBlacklist(uint indexed tokenId);
    event RemovedFromBlacklist(uint indexed tokenId);

    // State Variables
    string public _name; 
    string public _symbol;
    address private admin;

    mapping(bytes4 => bool) private _supportedInterfaces;
    mapping(uint => address) public _owners;
    mapping(address => uint) public _balances;
    mapping(uint => address) public _tokenApprovals;
    mapping(address => mapping(address => bool)) public _operatorApprovals; 
    mapping(uint => bool) private blacklist;

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != admin) revert ERC721RemilioNotAuthorized(msg.sender, 0);
        _;
    }

    // Constructor
    constructor(string memory name_, string memory symbol_, address _admin) ERC721(name_, symbol_) {
        admin = _admin;
        _name = name_;
        _symbol = symbol_;
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC165).interfaceId);
    }

    // External/Public Functions
    function balanceOf(address owner) public view virtual override returns (uint) {
        return _balances[owner];
    }

    function ownerOf(uint tokenId) public view virtual override returns (address) {
        return _owners[tokenId];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        _requiredOwned(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    function getApproved(uint tokenId) public view virtual override returns (address) {
        return _getApproved(tokenId);
    }

    function addToBlacklist(uint tokenId) public onlyOwner returns (bool) {
        require(_owners[tokenId] != address(0), "Token has no owner");
        blacklist[tokenId] = true;
        emit AddedToBlacklist(tokenId);
        return true;
    }

    function removeFromBlacklist(uint tokenId) public onlyOwner {
        require(_owners[tokenId] != address(0), "Token has no owner");
        blacklist[tokenId] = false;
        emit RemovedFromBlacklist(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint tokenId) public virtual override {
        if (to == address(0)) revert ERC721RemilioTransferToZeroAddress();
        address prevOwner = _update(to, tokenId, msg.sender);
        if (from != prevOwner) revert ERC721RemilioTransferFromIncorrectOwner();
    }

    function approve(address to, uint tokenId) public virtual override {
        _approve(to, tokenId, true);
    }

    function mint(address to, uint tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721RemilioInvalidReciever();
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721RemilioInvalidSender();
        }
    }

    function burn(uint tokenId) public virtual {
        address owner = _requiredOwned(tokenId);
        _update(address(0), tokenId, owner);
    }

    // Internal Functions
    function _isAuthorized(address owner, address spender, uint tokenId) internal view virtual override returns (bool) {
        if (spender == address(0)) revert ERC721RemilioNotAuthorized(spender, tokenId);
        return owner == spender || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender;
    }

    function _update(address to, uint tokenId, address auth) internal virtual override returns (address) {
        address from = _owners[tokenId];
        if (from == address(0)) revert ERC721RemilioDoesntExist(tokenId);
        if (!_isAuthorized(from, auth, tokenId)) revert ERC721RemilioNotAuthorized(auth, tokenId);
        if (_isTokenBlacklisted(tokenId)) revert ERC721RemilioBlacklisted(tokenId);

        _approve(address(0), tokenId, false);
        _balances[from] -= 1;
        if (to != address(0)) {
            _balances[to] += 1;
            _owners[tokenId] = to;
        }
        emit Transfer(from, to, tokenId);
        return from;
    }

    function _approve(address to, uint tokenId, bool emitEvent) internal virtual {
        address owner = _requiredOwned(tokenId);
        if (msg.sender != owner) revert ERC721RemilioApprovalCallerNotOwner(msg.sender);
        _tokenApprovals[tokenId] = to;
        if (emitEvent) {
            emit Approval(owner, to, tokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function _requiredOwned(uint tokenId) internal view virtual returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert ERC721RemilioDoesntExist(tokenId);
        return owner;
    }

    function _getApproved(uint tokenId) internal view virtual override returns (address) {
        _requiredOwned(tokenId);
        return _tokenApprovals[tokenId];
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual override {
        if (owner != msg.sender) revert ERC721RemilioApprovalCallerNotOwner(msg.sender);
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "Invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    function _isTokenBlacklisted(uint tokenId) internal view returns (bool) {
        return blacklist[tokenId];
    }
}
